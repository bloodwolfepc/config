{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "khal";
    #persistDirs = [
    #  ".cal"
    #  ".cont"
    #];
    sops.secrets = {
      "bwPass" = { };
      "bwUser" = { };
    };
    services.nextcloud-client = {
      enable = false;
      startInBackground = false;
    };
    programs.khal = {
      locale.timeformat = "%H:%M";
      enable = true;
    };
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;
    programs.khard.enable = true;

    accounts = let
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
        enable = true;
        collections = [ "${primaryCollection}" "bloodconnections" ];
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
    in {
      contact = {
        basePath = "/persist${config.home.homeDirectory}/.cont";
        accounts."bloodwolfe" = {
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
      calendar = {
        basePath = "/persist${config.home.homeDirectory}/.cal";
        accounts."bloodwolfe" = {
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
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
