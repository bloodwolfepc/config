{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "flatpak";
    services.flatpak.enable = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
