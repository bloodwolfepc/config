{
  pkgs,
  outputs,
  lib,
  ...
}:
let
  hyprkan = outputs.customPackages.x86_64-linux.hyprkan;
  hl-util = pkgs.writeShellScriptBin "hl-util" (builtins.readFile ./hl-util.sh);
in
{
  home.packages =
    with pkgs;
    [
      kanata-with-cmd
    ]
    ++ [
      hyprkan
      hl-util
    ];

  home.file.".config/kanata/kanata.kbd".source = ./config/kanata.kbd;

  systemd.user = {
    services."kanata" = {
      Unit = {
        Description = "Kanata service";
        After = "basic.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kanata-with-cmd}/bin/kanata --port 7070";
        TimeoutStopSec = "180";
        KillMode = "process";
        KillSignal = "SIGINT";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.hyprkan = {
    Unit = {
      description = "Kanata Layer Switcher";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.escapeShellArgs [
        "${hyprkan}/bin/hyprkan"
        "--log-level"
        "DEBUG"
        "-c"
        "${./hyprkan.json}"
      ];
      Restart = "on-failure";
      RestartSec = 5;
      Type = "simple";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
