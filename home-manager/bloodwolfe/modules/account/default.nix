{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = config.dotfiles.source;
  secret = name: "${config.xdg.configHome}/sops-nix/secrets/${name}";
in
{
  sops.secrets = {
    cloud-tinywolfe-net-username = { };
    cloud-tinywolfe-net-password = { };
    google-app_0 = { };
    tinywolfe-mail-password = { };
  };

  xdg.configFile = {
    "vdirsyncer/config".source = source "account/vdirsyncer.conf" ./vdirsyncer.conf;
    "khal/config".source = source "account/khal.conf" ./khal.conf;
    "khard/khard.conf".source = source "account/khard.conf" ./khard.conf;
    isyncrc.source = source "account/isyncrc" ./isyncrc;
    "neomutt/neomuttrc".source = source "account/neomuttrc" ./neomuttrc;
    "neomutt/accounts/tinywolfe".source = source "account/neomutt-tinywolfe" ./neomutt-tinywolfe;
    "neomutt/accounts/google".source = source "account/neomutt-google" ./neomutt-google;
    "neomutt/signature".source = source "account/signature" ./signature;
    "imapnotify/tinywolfe.json".source =
      source "account/imapnotify-tinywolfe.json" ./imapnotify-tinywolfe.json;
    "imapnotify/google.json".source = source "account/imapnotify-google.json" ./imapnotify-google.json;
  };

  home.packages = with pkgs; [
    isync
    khal
    khard
    neomutt
    vdirsyncer
  ];

  services.vdirsyncer = {
    enable = true;
    configFile = "${config.xdg.configHome}/vdirsyncer/config";
  };

  systemd.user.services = {
    mbsync-tinywolfe = {
      Unit = {
        Description = "Synchronize Tinywolfe mail";
        After = [ "sops-nix.service" ];
        ConditionPathExists = secret "tinywolfe-mail-password";
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /persist/home/bloodwolfe/.mail/tinywolfe";
        ExecStart = "${pkgs.isync}/bin/mbsync --config ${config.xdg.configHome}/isyncrc --verbose tinywolfe";
      };
    };

    mbsync-google = {
      Unit = {
        Description = "Synchronize Google mail";
        After = [ "sops-nix.service" ];
        ConditionPathExists = secret "google-app_0";
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /persist/home/bloodwolfe/.mail/bloodwolfe";
        ExecStart = "${pkgs.isync}/bin/mbsync --config ${config.xdg.configHome}/isyncrc --verbose google";
      };
    };

    imapnotify-tinywolfe = {
      Unit = {
        Description = "Watch Tinywolfe mail";
        After = [ "sops-nix.service" ];
        ConditionPathExists = secret "tinywolfe-mail-password";
      };
      Service = {
        ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify -conf ${config.xdg.configHome}/imapnotify/tinywolfe.json";
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.systemd
            pkgs.libnotify
          ]
        }";
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };

    imapnotify-google = {
      Unit = {
        Description = "Watch Google mail";
        After = [ "sops-nix.service" ];
        ConditionPathExists = secret "google-app_0";
      };
      Service = {
        ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify -conf ${config.xdg.configHome}/imapnotify/google.json";
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.systemd
            pkgs.libnotify
          ]
        }";
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers = {
    mbsync-tinywolfe = {
      Unit.Description = "Periodically synchronize Tinywolfe mail";
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = "5m";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    mbsync-google = {
      Unit.Description = "Periodically synchronize Google mail";
      Timer = {
        OnBootSec = "3m";
        OnUnitActiveSec = "5m";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
