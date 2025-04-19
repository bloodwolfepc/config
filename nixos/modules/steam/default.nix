{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "steam";
    hardware.steam-hardware.enable = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
