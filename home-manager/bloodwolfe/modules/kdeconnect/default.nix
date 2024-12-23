{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "kdeconnect";
    persistDirs = [
      ".config/kdeconnect"
    ];
    inherit config;
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
in {
  inherit (attrs) options config;
}
