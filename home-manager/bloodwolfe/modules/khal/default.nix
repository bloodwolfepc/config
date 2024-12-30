{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "khal";
    sops.secrets = {
      "bwPass" = { };
      "bwUser" = { };
    };
    programs.khal = {
      locale.timeformat = "%H:%M";
      enable = true;
    };
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    services.netcloud-client = {
      enable = true;
      startInBackground = true;
    };
    accounts.calendar = {
      accounts = {
        "bloodwolfe" = {
          primary = true;
          primaryCollection = "QC";
          remote = {
            type = "caldav";
            url = "https://cloud.waterdreamer.net/remote.php";
            passwordCommand = [
              "cat"
              "${config.sops.secrets.bwPass.path}"
            ];
          };
          vdirsyncer = {
            enable = true;
            collections = [ "from a" ];
            userNameCommand = [
              "cat"
              "${config.sops.secrets.bwUser.path}"
            ];
            metadata = [
              "color"
              "displayname"
            ];
          khal = {
            type = "discover";
            enable = true;
          };
        };
      };
    };
  };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
