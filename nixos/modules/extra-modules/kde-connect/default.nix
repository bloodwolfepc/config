{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "kde-connect";
    programs.kdeconnect.enable = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
