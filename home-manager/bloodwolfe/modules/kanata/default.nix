{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    kanata-with-cmd
  ];

  home.file.".config/kanata/kanata.kbd".source = ./kanata.kbd;

  systemd.user = {
    services."kanata" = {
      Unit = {
        Description = "Kanata service";
        After = "basic.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kanata-with-cmd}/bin/kanata";
        TimeoutStopSec = "180";
        KillMode = "process";
        KillSignal = "SIGINT";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
