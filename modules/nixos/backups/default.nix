{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.snapshotBackups;
  nameOf = job: "${cfg.namespace}-${job}";
  names = map nameOf (builtins.attrNames cfg.jobs);
  status = cfg.statusDirectory;
  statusArg = lib.escapeShellArg status;
  safePath =
    path:
    lib.hasPrefix "/" path
    && !(builtins.elem ".." (lib.splitString "/" path))
    && !lib.hasInfix "\n" path
    && !lib.hasInfix "\r" path
    && !lib.hasInfix "%" path;
  uid = if cfg.notifyUser == null then null else config.users.users.${cfg.notifyUser}.uid;
  bus = "/run/user/${toString uid}/bus";
  notifyUnit = "${cfg.namespace}-backup-notify@%n.service";
  lockRestic =
    guard:
    import ./locked-restic.nix {
      inherit pkgs lib guard;
      package = cfg.settings.package or pkgs.restic;
      lockFile = "/run/${cfg.namespace}-restic.lock";
    };
  lockedRestic = lockRestic "";
  maintenanceRestic = lockRestic ''
    states=$(${pkgs.systemd}/bin/systemctl show --value --property=ActiveState ${
      lib.escapeShellArgs (map (name: "restic-backups-${name}.service") names)
    })
    if ${pkgs.gnugrep}/bin/grep -Eq '^(active|activating|deactivating|reloading)$' <<< "$states"; then
      echo 'Backup jobs are busy; maintenance deferred' >&2; exit 1
    fi
    for name in ${lib.escapeShellArgs names}; do
      test -f ${statusArg}/$name.success
      test ! -e ${statusArg}/$name.failed
    done
  '';
  common = cfg.settings // {
    package = lockedRestic;
    initialize = false;
    runCheck = true;
    pruneOpts = [ ];
    timerConfig = cfg.timerConfig;
  };
  jobs = lib.mapAttrs' (
    name: selection:
    lib.nameValuePair (nameOf name) (
      common
      // selection
      // {
        paths = map (
          path: if lib.hasPrefix "/" path then path else "${lib.removeSuffix "/" cfg.basePath}/${path}"
        ) selection.paths;
        exclude = (cfg.settings.exclude or [ ]) ++ selection.exclude;
        package = lockedRestic;
        initialize = false;
        runCheck = true;
        pruneOpts = [ ];
        extraBackupArgs = [
          "--host=${config.networking.hostName}"
          "--tag=${nameOf name}"
        ]
        ++ (selection.extraBackupArgs or (cfg.settings.extraBackupArgs or [ ]));
      }
    )
  ) cfg.jobs;
  resultScript =
    name:
    pkgs.writeShellScript "${name}-result" ''
      if [[ "''${SERVICE_RESULT:-failed}" != success ]]; then touch ${statusArg}/${name}.failed; fi
    '';
  successScript =
    name:
    pkgs.writeShellScript "${name}-success" ''
      set -e
      touch ${statusArg}/${name}.success
      rm -f ${statusArg}/${name}.failed
    '';
in
{
  options.services.snapshotBackups = {
    enable = lib.mkEnableOption "isolated snapshot-backed native restic jobs";
    namespace = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Prefix for job names, tags, locks and notification units.";
    };
    source = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      apply = path: if path == "/" then path else lib.removeSuffix "/" path;
      description = "Btrfs source mount; nested selected storage is rejected.";
    };
    basePath = lib.mkOption {
      type = lib.types.str;
      default = cfg.source;
      description = "Physical directory for relative selections; exposed in the snapshot as BACKUP_ROOT.";
    };
    snapshotDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${lib.removeSuffix "/" cfg.source}/.${cfg.namespace}-backup-snapshots";
    };
    statusDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${lib.removeSuffix "/" cfg.source}/system/${cfg.namespace}-backup-status";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Common native restic settings, including repository and runtime credential files.";
    };
    jobs = lib.mkOption {
      default = { };
      description = "Job selections and native restic overrides; relative paths use basePath.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.anything;
          options = {
            paths = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
    };
    timerConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "2m";
      };
    };
    maintenanceTimerConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = {
        OnCalendar = "Sun *-*-* 06:00:00";
        Persistent = true;
      };
    };
    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
    requires = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Units providing runtime credentials or other prerequisites.";
    };
    notifyUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional local notification recipient, with an explicitly declared UID.";
    };
  };

  imports = [
    (import ./snapshot-restic.nix {
      source = cfg.source;
      basePath = cfg.basePath;
      snapshotBase = cfg.snapshotDirectory;
      jobs = if cfg.enable then jobs else { };
    })
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all safePath [
          cfg.source
          cfg.basePath
          cfg.snapshotDirectory
          cfg.statusDirectory
        ];
        message = "Backup storage paths must be absolute, single-line and free of parent traversal or systemd specifiers.";
      }
      {
        assertion = lib.all (path: builtins.match "[^[:space:]]+" path != null) [
          cfg.source
          cfg.snapshotDirectory
          cfg.statusDirectory
        ];
        message = "Backup mount, snapshot and status directories must not contain whitespace.";
      }
      {
        assertion = lib.all (path: builtins.match "/[A-Za-z0-9_./@+-]*" path != null) [
          cfg.source
          cfg.snapshotDirectory
        ];
        message = "Backup mount and snapshot paths must be literal Btrbk configuration paths.";
      }
      {
        assertion =
          (cfg.settings.command or [ ]) == [ ]
          && lib.all (job: (job.command or [ ]) == [ ]) (builtins.attrValues cfg.jobs);
        message = "Snapshot backup jobs accept file selections, not command streams.";
      }
      {
        assertion = lib.all (
          job:
          lib.all
            (field: (job.${field} or (cfg.settings.${field} or null)) == (cfg.settings.${field} or null))
            [
              "repository"
              "repositoryFile"
              "passwordFile"
              "passwordCommand"
              "environmentFile"
              "rcloneConfigFile"
              "rcloneConfig"
              "rcloneOptions"
              "extraOptions"
            ]
        ) (builtins.attrValues cfg.jobs);
        message = "Snapshot backup jobs must share the configured maintenance repository.";
      }
      {
        assertion = cfg.jobs != { };
        message = "Snapshot backups require at least one job.";
      }
      {
        assertion = !(builtins.hasAttr "maintenance" cfg.jobs);
        message = "The snapshot backup job name 'maintenance' is reserved.";
      }
      {
        assertion = builtins.match "[A-Za-z0-9][A-Za-z0-9_.-]*" cfg.namespace != null;
        message = "Unsafe snapshot backup namespace.";
      }
      {
        assertion =
          cfg.basePath == cfg.source || lib.hasPrefix "${lib.removeSuffix "/" cfg.source}/" cfg.basePath;
        message = "Backup basePath must be inside its source mount.";
      }
      {
        assertion = cfg.notifyUser == null || uid != null;
        message = "Backup notifications require an explicitly declared recipient UID.";
      }
    ];
    systemd.tmpfiles.rules = [ "d ${status} 0755 root root -" ];
    systemd.services =
      lib.mapAttrs' (
        name: _:
        lib.nameValuePair "restic-backups-${name}" {
          requires = cfg.requires;
          after = cfg.requires;
          path = [ pkgs.rclone ];
          unitConfig.OnFailure = lib.optional (cfg.notifyUser != null) notifyUnit;
          postStop = lib.mkAfter "${resultScript name}";
          serviceConfig = {
            ExecStartPost = toString (successScript name);
            Restart = "on-failure";
            RestartSec = "30min";
          };
        }
      ) jobs
      // {
        "restic-backups-${cfg.namespace}-maintenance" = {
          path = [ pkgs.rclone ];
          requires = cfg.requires;
          after = cfg.requires;
          unitConfig.OnFailure = lib.optional (cfg.notifyUser != null) notifyUnit;
          serviceConfig = {
            TimeoutStartSec = "6h";
            Restart = "on-failure";
            RestartSec = "1h";
          };
        };
      }
      // lib.optionalAttrs (cfg.notifyUser != null) {
        "${cfg.namespace}-backup-notify@" = {
          description = "Notify about failed backup %i";
          unitConfig.ConditionPathExists = bus;
          environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=${bus}";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.notifyUser;
            ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical 'Backup failed' '%i: see the system journal'";
          };
        };
        "${cfg.namespace}-backup-stale" = {
          description = "Desktop warning for missing/stale backups";
          unitConfig.ConditionPathExists = bus;
          environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=${bus}";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.notifyUser;
          };
          path = [
            pkgs.coreutils
            pkgs.libnotify
          ];
          script = ''
            now=$(date +%s)
            urgency=normal
            stale=()
            for name in ${lib.escapeShellArgs names}; do
              if [[ -e ${statusArg}/$name.failed ]]; then stale+=("$name (failed)"); urgency=critical; continue; fi
              file=${statusArg}/$name.success
              if [[ ! -f "$file" ]]; then stale+=("$name (missing)"); urgency=critical; continue; fi
              age=$((now - $(stat -c %Y "$file")))
              if (( age < 0 || age >= 172800 )); then stale+=("$name"); fi
              if (( age < 0 || age >= 604800 )); then urgency=critical; fi
            done
            if (( ''${#stale[@]} )); then
              notify-send --urgency="$urgency" 'Backups need attention' "''${stale[*]}"
            fi
          '';
        };
      };
    systemd.timers = lib.optionalAttrs (cfg.notifyUser != null) {
      "${cfg.namespace}-backup-stale" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          OnBootSec = "10min";
          Persistent = true;
        };
      };
    };
    services.restic.backups."${cfg.namespace}-maintenance" = common // {
      package = maintenanceRestic;
      paths = [ ];
      dynamicFilesFrom = null;
      command = [ ];
      backupCleanupCommand = null;
      timerConfig = cfg.maintenanceTimerConfig;
      backupPrepareCommand = ''
        #!${pkgs.runtimeShell}
        set -Eeuo pipefail
        ${lib.getExe maintenanceRestic} check
      '';
      pruneOpts = [
        "--host ${config.networking.hostName}"
      ]
      ++ map (name: "--tag ${name}") names
      ++ [ "--group-by host,tags" ]
      ++ cfg.pruneOpts;
    };
  };
}
