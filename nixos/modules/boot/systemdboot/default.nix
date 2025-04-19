{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "systemd-boot";
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
