{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "syncthing";
    packages = with pkgs; [
      (writeShellScriptBin "syncthing-gen-config" ''
        ${syncthing}/bin/syncthing -generate=myconfig
      '')
      syncthing
    ];
    services.syncthing = { #8384
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = { 
          "navi" = { id = "IOZE6I7-TPMOBII-WVPA62C-ZWJEHAO-HSDYXS3-SYBX6OI-NXBLSI3-2YQUJA4" ; };
          "lapis" = { id = "KKJZICE-YNDNRKY-2IFRHWP-76JK2D2-C27NC3V-OYYPDQY-BZ5SBNP-3CZ3DQD" ; };
          "angel" = { id = "DCWVWTS-URQEQL6-BC6CD3H-CJB3343-FF6FZDR-VJ6IH4W-IRTI3LS-CCC45Q6" ; };
          "android" = { id = "H6CLZR5-J4H7S4P-2OVWJXB-BKJQUTF-7WKT2OE-A7EI5QP-NSXOU32-VMYD6AO" ; };
        };
        folders."/sync${config.home.homeDirectory}/.extra-syncs" = {
          path = "/sync${config.home.homeDirectory}/.extra-syncs";
          devices = [ "angel" "navi" ];
          ignorePerms = false;
        };
      };
    };
    sops.secrets = {
      "syncthing-password" = { };
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
