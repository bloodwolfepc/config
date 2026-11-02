{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gameSaves;
  package = import ./package.nix {
    inherit pkgs;
    inherit (cfg)
      configDirectory
      stateDirectory
      backupDirectory
      inboxDirectory
      statusDirectory
      refreshCommand
      ;
  };
in
{
  options.gameSaves = {
    enable = lib.mkEnableOption "native Ludusavi discovery and backups";
    configDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/game-saves";
    };
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/game-saves";
    };
    backupDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/nextcloud-sync/game-saves";
    };
    refreshCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Existing transport's blocking inbox refresh before a wrapped launch.";
    };
    inboxDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/nextcloud-sync/game-saves-inbox";
    };
    statusDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/nextcloud-sync/game-saves-status";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };
  config = lib.mkIf cfg.enable {
    gameSaves.package = package;
    home.packages = [
      package
      pkgs.ludusavi
    ];
    systemd.user.services.game-saves-backup = {
      Unit.Description = "Back up discovered games with Ludusavi";
      Service = {
        Type = "oneshot";
        ExecStart = "${package}/bin/game-saves backup --force";
        UMask = "0077";
      };
    };
    systemd.user.services.game-saves-receive = {
      Unit.Description = "Apply explicit phone handoffs through native Ludusavi";
      Service = {
        Type = "oneshot";
        ExecStart = "${package}/bin/game-saves receive";
        UMask = "0077";
      };
    };
    systemd.user.timers.game-saves-receive = {
      Timer = {
        OnBootSec = "2min";
        OnUnitInactiveSec = "2min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
    systemd.user.timers.game-saves-backup = {
      Timer = {
        OnCalendar = "*-*-* 02:30:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
