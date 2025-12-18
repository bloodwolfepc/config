{
  lib,
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    "bwPass" = { };
    "bwUser" = { };
    "google-app_0" = { };
  };
  accounts =
    let
      primaryCollection = "waterfall";
      remote = type: {
        inherit type;
        url = "https://cloud.waterdreamer.net/remote.php";
        passwordCommand = [
          "cat"
          "${config.sops.secrets.bwPass.path}"
        ];
      };
      vdirsyncer = {
        enable = false;
        collections = [
          "${primaryCollection}"
          "bloodconnections"
        ];
        userNameCommand = [
          "cat"
          "${config.sops.secrets.bwUser.path}"
        ];
        metadata = [
          "color"
          "displayname"
        ];
        conflictResolution = "local wins";
      };
      khal = {
        enable = true;
      };
    in
    {
      contact = {
        basePath = "/persist${config.home.homeDirectory}/.cont";
        accounts = {
          "bloodwolfe" = {
            local = {
              type = "filesystem";
              fileExt = ".vcf";
            };
            remote = remote "carddav";
            khard = {
              enable = true;
              defaultCollection = primaryCollection;
            };
            khal = lib.mkMerge [
              khal
              { collections = vdirsyncer.collections; }
            ];
            inherit vdirsyncer;
          };
        };
      };
      calendar = {
        basePath = "/persist${config.home.homeDirectory}/.cal";
        accounts = {
          "bloodwolfe" = {
            primary = true;
            remote = remote "caldav";
            khal = lib.mkMerge [
              khal
              { type = "discover"; }
            ];
            inherit vdirsyncer primaryCollection;
          };
        };
      };
      email = {
        maildirBasePath = "/persist${config.home.homeDirectory}/.mail";
        accounts = {
          "bloodwolfe" =
            let
              mbsync = "${config.programs.mbsync.package}/bin/mbsync";
              pass = "${config.programs.password-store.package}/bin/pass";
              common = rec {
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
              };
            in
            rec {
              primary = true;
              userName = address;
              address = "bloodwolfepc@gmail.com";
              passwordCommand = ''cat ${config.sops.secrets."google-app_0".path}'';
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
                enable = false; # fix user service startup time
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
            }
            // common;
        };
      };
    };
  services = {
    nextcloud-client = {
      enable = false;
      startInBackground = false;
    };
    vdirsyncer = {
      enable = false;
    };

    imapnotify = {
      enable = true;
    };
    mbsync = {
      enable = false;
    };
  };
  programs = {
    khal = {
      locale.timeformat = "%H:%M";
      enable = true;
    };
    vdirsyncer = {
      enable = false;
    };
    khard = {
      enable = true;
    };

    mbsync = {
      enable = false;
    };
    msmtp = {
      enable = true;
    };
    neomutt = {
      enable = true;
    };
  };
}
