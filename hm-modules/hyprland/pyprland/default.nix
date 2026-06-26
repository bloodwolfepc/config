{ lib, pkgs, ... }: {
  systemd.user.services.pyprland = {
    Unit = {
      Description = "Starts pyprland daemon";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
      StartLimitIntervalSec = "600";
      StartLimitBurst = "5";
    };
    Service = {
      Type = "simple";
      ExecStart = lib.escapeShellArgs [
        "${pkgs.pyprland}/bin/pypr"
        "--debug"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  home.file.".config/pypr/config.toml".source = ./config.toml;
  home.packages = with pkgs; [ pyprland ];
}
