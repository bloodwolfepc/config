{ lib, pkgs, ... }: {
  systemd.user.services.wayscriber = {
    Unit = {
      Description = "Starts wayscriber daemon";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
      StartLimitIntervalSec = "600";
      StartLimitBurst = "5";
    };
    Service = {
      Type = "simple";
      ExecStart = lib.escapeShellArgs [
        "${pkgs.wayscriber}/bin/wayscriber"
        "--daemon"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Environment = {
      PATH = pkgs.lib.makeBinPath [ pkgs.wayscriber ];
    };
  };
  home.file.".config/wayscriber/config.toml".source = ./config.toml;
  home.packages = with pkgs; [ wayscriber ];
}
