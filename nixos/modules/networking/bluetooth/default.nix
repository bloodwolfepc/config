{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "bluetooth";
    hardware.bluetooth = {
      enable = true;
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
