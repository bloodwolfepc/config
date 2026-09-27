{ pkgs, ... }:
{
  imports = [
    ../modules
  ];
  dotfiles.mutable = true;

  systemd.user.services.lemonade = {
    Unit = {
      Description = "Local clipboard bridge for SSH sessions";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lemonade}/bin/lemonade server --allow=127.0.0.1,::1";
      Environment = "PATH=${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.wl-clipboard
        ]
      }";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = with pkgs; [
    xf86_input_wacom
    wine
    wiremix
    ego

    (writeShellScriptBin "ddc-default" ''
      ddcutil setvcp 10 45
      ddcutil setvcp 87 50
    '')
    (writeShellScriptBin "ddc-comp" ''
      ddcutil setvcp 10 100
      ddcutil setvcp 87 70
    '')
  ];
}
