{
  config,
  lib,
  pkgs,
  ...
}:
let
  secret = name: config.sops.secrets.${name}.path;
  stateDirectory = "${config.xdg.stateHome}/angel-state-backup";
  groups = {
    state = "00";
    legcord = "10";
    terraria = "20";
    anki = "30";
    firefox = "40";
  };
  unitName = group: if group == "state" then "angel-state-backup" else "angel-state-backup-${group}";
  backup = pkgs.writeShellApplication {
    name = "angel-state-backup";
    runtimeInputs = [
      pkgs.python3
      pkgs.coreutils
      pkgs.procps
      pkgs.rclone
      pkgs.restic
    ];
    text = ''
      export ANGEL_BACKUP_HOME=${lib.escapeShellArg config.home.homeDirectory}
      export ANGEL_BACKUP_STATE=${lib.escapeShellArg stateDirectory}
      export ANGEL_BACKUP_USERNAME_FILE=${lib.escapeShellArg (secret "cloud-tinywolfe-net-username")}
      export ANGEL_BACKUP_CLOUD_PASSWORD_FILE=${lib.escapeShellArg (secret "cloud-tinywolfe-net-password")}
      export RESTIC_PASSWORD_FILE=${lib.escapeShellArg (secret "restic-angel-nextcloud-password")}
      exec python3 ${./backup.py} "$@"
    '';
  };
in
{
  sops.secrets.restic-angel-nextcloud-password = { };
  home.packages = [ backup ];
  home.activation.artProjectDirectories = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/gimp"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/krita"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/beeref"}
  '';
  home.persistence."/persist".directories = [
    "projects/art"
    {
      directory = ".local/state/angel-state-backup";
      mode = "0700";
    }
  ];
  systemd.user = {
    services = lib.mapAttrs' (
      group: _:
      lib.nameValuePair (unitName group) {
        Unit = {
          Description = "Encrypted versioned Angel recovery backup: ${group}";
          After = [
            "network-online.target"
            "sops-nix.service"
          ];
          Wants = [ "network-online.target" ];
          ConditionPathExists = [
            (secret "cloud-tinywolfe-net-username")
            (secret "cloud-tinywolfe-net-password")
            (secret "restic-angel-nextcloud-password")
          ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe backup} scheduled --group ${group}";
          UMask = "0077";
          Nice = 10;
          IOSchedulingClass = "idle";
          SuccessExitStatus = [ 75 ];
          TimeoutStartSec = "6h";
        };
      }
    ) groups;
    timers = lib.mapAttrs' (
      group: minute:
      lib.nameValuePair (unitName group) {
        Unit.Description = "Daily Angel ${group} backup, with hourly app-closed retries";
        Timer = {
          OnCalendar = "*-*-* *:${minute}:00";
          RandomizedDelaySec = "2m";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      }
    ) groups;
  };
}
