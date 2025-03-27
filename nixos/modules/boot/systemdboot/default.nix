{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "systemd-boot";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
