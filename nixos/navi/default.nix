{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    #TODO: nixos hardware modules
    ./hardware-configuration.nix
    ../setup

    ./ddns.nix
    ./borg.nix
  ];
  config =
    let
      inherit (config.sysglobals.list)
        require-nixos
        require-pc
        srv-progs
        used-progs
        gaming-progs
        ;
      enable = {
        list =
          [
            "bloodwolfe"
            "audio"
          ]
          ++ require-nixos
          ++ srv-progs;
        value = {
          enable = true;
          persist.enable = true;
        };
      };
      configured = lib.listToAttrs (
        map (name: {
          inherit name;
          inherit (enable) value;
        }) enable.list
      );
    in
    {
      inherit configured;
      networking = {
        hostName = "navi";
        useDHCP = lib.mkForce false;
        interfaces = {
          "br0" = {
            useDHCP = true;
          };
        };
        bridges = {
          "br0" = {
            interfaces = [ "eno1" ];
          };
        };
        nat = {
          enable = true;
          enableIPv6 = true;
          internalInterfaces = [ "ve-+" ];
          externalInterface = "br0";
        };
      };
      services.resolved.enable = true;
      hardware.raid.HPSmartArray.enable = true;
    };
}
