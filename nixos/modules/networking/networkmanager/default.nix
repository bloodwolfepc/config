{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "networkmanager";
    networking = {
      networkmanager = {
        enable = true;
        unmanaged = [ "interface-name:ve-*" ];
      };
      useDHCP = lib.mkForce false;
    };
    services.resolved.enable = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
