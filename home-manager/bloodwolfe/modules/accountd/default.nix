{
  config,
  pkgs,
  ...
}:
let
  primaryCollection = "waterfall";
  collections = [
    "${primaryCollection}"
    "rainbow"
  ];
  persistedHomeDir = "/persist${config.home.homeDirectory}/";
  passwordCommand = [
    "cat"
    "${config.sops.secrets."cloud-waterdreamer-net-password".path}"
  ];
  userNameCommand = [
    "cat"
    "${config.sops.secrets."cloud-waterdreamer-net-username".path}"
  ];
  setRemoteForType = type: {
    inherit type passwordCommand;
    # url = "https://cloud.waterdreamer.net/remote.php";
    url = "https://cloud.waterdreamer.net/remote.php/dav/principals/users/january";
  };
in
{
  sops.secrets = {
    "cloud-waterdreamer-net-username" = { };
    "cloud-waterdreamer-net-password" = { };
    "google-app_0" = { };
  };
  accounts = {
    contact = {
      basePath = persistedHomeDir + ".cont";
      accounts."bloodwolfe" = {
        local = {
          type = "filesystem";
          fileExt = ".vcf";
        };
        remote = setRemoteForType "carddav";
        khard = {
          enable = true;
        };
        khal = {
          enable = true;
          inherit collections;
        };
        vdirsyncer = {
          enable = true;
          inherit userNameCommand collections;
          metadata = [
            "color"
            "displayname"
          ];
          conflictResolution = "local wins";
        };
      };
    };

    calendar = {
      basePath = persistedHomeDir + ".cal";
      accounts.bloodwolfe = {
        primary = true;
        inherit primaryCollection;
        remote = setRemoteForType "caldav";
        khal = {
          enable = true;
          type = "discover";
        };
        vdirsyncer = {
          enable = true;
          inherit userNameCommand collections;
          metadata = [
            "color"
            "displayname"
          ];
          conflictResolution = "local wins";
        };
      };
    };

    email = {
      maildirBasePath = persistedHomeDir + ".mail";
      accounts."bloodowlfe" = rec {

        realName = "Marley Schabert";
        gpg = {
          key = "1616 47C1 14E2 1F60 A186 E252 B748 57A7 02B0 C92B";
          signByDefault = true;
        };
        signature = {
          showSignature = "append";
          text = ''
            ${realName}

            https://waterdreamer.net
            PGP: ${gpg.key}
          '';
        };

        primary = true;
        userName = "bloodwolfe";
        passwordCommand = "cat ${config.sops.secrets."google-app_0".path}";
        address = "bloodwolfepc@gmail.com";
        flavor = "gmail.com";
        imap = {
          host = "imap.gmail.com";
        };
        offlineimap = {
          enable = true;
        };
        imapnotify = {
          enable = true;
          boxes = [ "inbox" ];
          onNotifyPost = ''${pkgs.libnotify}/bin/notify-send "mail"'';
          onNotify = "${pkgs.isync}/bin/mbsync -a";
        };
        smtp = {
          host = "smtp.gmail.com";
        };
        mbsync = {
          enable = true;
          create = "maildir";
          expunge = "both";
        };
        folders = {
          inbox = "inbox";
          drafts = "drafts";
          sent = "sent";
          trash = "trash";
        };
        neomutt = {
          enable = true;
        };
      };
    };
  };

  services = {
    vdirsyncer = {
      enable = true;
    };
    imapnotify = {
      enable = true;
    };
    mbsync = {
      enable = true;
    };
  };

  programs = {
    khal = {
      locale.timeformat = "%H:%M";
      enable = true;
    };
    vdirsyncer = {
      enable = true;
    };
    khard = {
      enable = true;
    };

    mbsync = {
      enable = true;
    };
    msmtp = {
      enable = true;
    };
    neomutt = {
      enable = true;
    };
  };
}
