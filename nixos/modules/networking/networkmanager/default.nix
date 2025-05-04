{
  lib,
  config,
  pkgs,
  ...
}:
let
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
    #packages = with pkgs; [
    #  wifi-password
    #];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
