{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "bloodwolfe";
  uid = toString config.users.users.${user}.uid;
  home = "/persist${config.users.users.${user}.home}";
  secret = name: config.home-manager.users.${user}.sops.secrets.${name}.path;
  auth = "/run/angel-backup-credentials";
  status = "/persist/system/angel-backup-status";
  selections = import ./paths.nix { inherit home lib; };
  minutes = {
    state = "00";
    legcord = "10";
    terraria = "20";
    anki = "30";
    firefox = "40";
  };
  # Native backup/check/prune commands share a repo; queue them instead of
  # letting an exclusive check collide with another group's upload.
  lockRestic =
    guard:
    import ./locked-restic.nix {
      inherit pkgs lib guard;
      lockFile = "/run/angel-restic.lock";
    };
  lockedRestic = lockRestic "";
  maintenanceRestic = lockRestic ''
    states=$(${pkgs.systemd}/bin/systemctl show --value --property=ActiveState ${
      lib.escapeShellArgs (map (name: "restic-backups-${name}.service") nativeNames)
    })
    if ${pkgs.gnugrep}/bin/grep -Eq '^(active|activating|deactivating|reloading)$' <<< "$states"; then
      echo 'Backup jobs are busy; maintenance deferred' >&2; exit 1
    fi
    for name in ${lib.escapeShellArgs nativeNames}; do
      test -f ${status}/$name.success
      test ! -e ${status}/$name.failed
    done
  '';
  common = {
    package = lockedRestic;
    repository = "rclone:angel:Backups/angel-state";
    passwordFile = "${auth}/password";
    rcloneConfigFile = "${auth}/rclone.conf";
    initialize = false;
    runCheck = true;
  };
  jobs = lib.mapAttrs' (
    group: selection:
    lib.nameValuePair "angel-${group}" (
      common
      // selection
      // {
        extraBackupArgs = [
          "--host=angel"
          "--tag=angel-${group}"
        ];
        timerConfig = {
          OnCalendar = "*-*-* 03:${minutes.${group} or "50"}:00";
          Persistent = true;
          RandomizedDelaySec = "2m";
        };
      }
      // lib.optionalAttrs (group == "state") {
        # The one remaining transformation: keep preferences without proxy credentials.
        backupPrepareCommand = ''
          file="$RUNTIME_DIRECTORY/view/home/${user}/.config/millennium/config.json"
          if [[ -f "$file" && ! -L "$file" ]]; then
            ${lib.getExe pkgs.jq} 'with_entries(select(.key == "general" or .key == "themes" or .key == "notifications" or .key == "plugins" or .key == "misc"))' "$file" > "$RUNTIME_DIRECTORY/millennium.json"
          else
            printf '{}\n' > "$RUNTIME_DIRECTORY/millennium.json"
          fi
        '';
        dynamicFilesFrom = ''printf '%s\n' "$RUNTIME_DIRECTORY/millennium.json"'';
      }
    )
  ) selections;
  nativeNames = builtins.attrNames jobs;
  stopStatus =
    name:
    pkgs.writeShellScript "${name}-result" ''
      if [[ "''${SERVICE_RESULT:-failed}" != success ]]; then touch ${status}/${name}.failed; fi
    '';
  success =
    name:
    pkgs.writeShellScript "${name}-success" ''
      set -e
      touch ${status}/${name}.success
      rm -f ${status}/${name}.failed
    '';
in
{
  imports = [
    (import ./snapshot-restic.nix {
      source = "/persist";
      inherit jobs;
    })
  ];
  systemd.tmpfiles.rules = [ "d ${status} 0755 root root -" ];
  # Decrypt through the existing user SOPS service, then cache only backup credentials
  # in a root-private runtime directory. Uploads survive logging out; no disk cache.
  systemd.services = {
    angel-backup-credentials = {
      wants = [ "user@${uid}.service" ];
      after = [ "user@${uid}.service" ];
      unitConfig.OnFailure = [ "angel-backup-notify@%n.service" ];
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = "angel-backup-credentials";
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = "yes";
        UMask = "0077";
      };
      postStop = ''
        if [[ "''${SERVICE_RESULT:-failed}" != success ]]; then
          for name in ${lib.escapeShellArgs nativeNames}; do touch ${status}/$name.failed; done
        fi
      '';
      script = ''
        set +x
        set -Eeuo pipefail
        ${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.coreutils}/bin/env XDG_RUNTIME_DIR=/run/user/${uid} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus ${pkgs.systemd}/bin/systemctl --user start sops-nix.service
        username=$(<${lib.escapeShellArg (secret "cloud-tinywolfe-net-username")})
        [[ -n "$username" && "$username" != *$'\n'* && "$username" != *$'\r'* ]] || exit 1
        encoded=$(printf '%s' "$username" | ${lib.getExe pkgs.jq} -sRr @uri)
        obscured=$(${lib.getExe pkgs.rclone} obscure - < ${lib.escapeShellArg (secret "cloud-tinywolfe-net-password")})
        printf '[angel]\ntype = webdav\nvendor = nextcloud\nurl = https://cloud.tinywolfe.net/remote.php/dav/files/%s/\nuser = %s\npass = %s\n' "$encoded" "$username" "$obscured" > ${auth}/rclone.conf.new
        ${pkgs.coreutils}/bin/install -m 600 ${lib.escapeShellArg (secret "restic-angel-nextcloud-password")} ${auth}/password.new
        mv ${auth}/rclone.conf.new ${auth}/rclone.conf
        mv ${auth}/password.new ${auth}/password
        unset username encoded obscured
      '';
    };
  }
  // lib.mapAttrs' (
    name: _:
    lib.nameValuePair "restic-backups-${name}" {
      requires = [ "angel-backup-credentials.service" ];
      after = [ "angel-backup-credentials.service" ];
      path = [ pkgs.rclone ];
      unitConfig.OnFailure = [ "angel-backup-notify@%n.service" ];
      postStop = lib.mkAfter "${stopStatus name}";
      serviceConfig = {
        ExecStartPost = toString (success name);
        Restart = "on-failure";
        RestartSec = "30min";
      };
    }
  ) jobs
  // {
    "restic-backups-angel-maintenance" = {
      path = [ pkgs.rclone ];
      serviceConfig = {
        TimeoutStartSec = "6h";
        Restart = "on-failure";
        RestartSec = "1h";
      };
      requires = [ "angel-backup-credentials.service" ];
      after = [ "angel-backup-credentials.service" ];
      unitConfig.OnFailure = [ "angel-backup-notify@%n.service" ];
    };
    "angel-backup-notify@" = {
      description = "Notify about failed backup %i";
      unitConfig.ConditionPathExists = "/run/user/${uid}/bus";
      environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical 'Backup failed' '%i: see the system journal'";
      };
    };
    angel-backup-stale = {
      description = "Desktop warning for missing/stale backups";
      unitConfig.ConditionPathExists = "/run/user/${uid}/bus";
      environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
      serviceConfig = {
        Type = "oneshot";
        User = user;
      };
      path = [
        pkgs.coreutils
        pkgs.libnotify
      ];
      script = ''
        now=$(date +%s)
        urgency=normal
        stale=()
        for name in ${lib.escapeShellArgs nativeNames}; do
          if [[ -e ${status}/$name.failed ]]; then stale+=("$name (failed)"); urgency=critical; continue; fi
          file=${status}/$name.success
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
  systemd.timers.angel-backup-stale = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      OnBootSec = "10min";
      Persistent = true;
    };
  };
  services.restic.backups.angel-maintenance = common // {
    package = maintenanceRestic;
    paths = [ ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 06:00:00";
      Persistent = true;
    };
    # A failed/partial attempt remains recorded across reboots. Do not prune until
    # every group has subsequently completed a checked backup, and none is active.
    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      set -Eeuo pipefail
      ${lib.getExe maintenanceRestic} check
    '';
    pruneOpts = [
      "--host angel"
    ]
    ++ map (group: "--tag angel-${group}") (builtins.attrNames selections)
    ++ [
      "--group-by host,tags"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
}
