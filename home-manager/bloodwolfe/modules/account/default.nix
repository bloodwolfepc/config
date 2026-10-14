{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = config.dotfiles.source;
in
{
  sops.secrets = {
    cloud-waterdreamer-net-username = { };
    cloud-waterdreamer-net-password = { };
    google-app_0 = { };
  };

  xdg.configFile = {
    "vdirsyncer/config".source = source "account/vdirsyncer.conf" ./vdirsyncer.conf;
    "khal/config".source = source "account/khal.conf" ./khal.conf;
    "khard/khard.conf".source = source "account/khard.conf" ./khard.conf;
    isyncrc.source = source "account/isyncrc" ./isyncrc;
    "neomutt/neomuttrc".source = source "account/neomuttrc" ./neomuttrc;
    "neomutt/signature".source = source "account/signature" ./signature;
    "imapnotify/bloodwolfe.json".source =
      source "account/imapnotify-bloodwolfe.json" ./imapnotify-bloodwolfe.json;
  };

  home.packages = with pkgs; [
    isync
    khal
    khard
    msmtp
    neomutt
    vdirsyncer
  ];

  services = {
    vdirsyncer = {
      enable = true;
      configFile = "${config.xdg.configHome}/vdirsyncer/config";
    };
    mbsync = {
      enable = true;
      configFile = "${config.xdg.configHome}/isyncrc";
    };
  };

  systemd.user.services.imapnotify-bloodwolfe = {
    Unit.Description = "imapnotify for bloodwolfe";
    Service = {
      ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify -conf ${config.xdg.configHome}/imapnotify/bloodwolfe.json";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.isync
          pkgs.libnotify
        ]
      }";
      Restart = "always";
      RestartSec = 30;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
