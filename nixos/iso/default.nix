{
  config,
  inputs,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ../setup
    ./hardware-configuration.nix
  ];

  config =
    let
      inherit (config.sysglobals.list)
        require-nixos
        ;
      enable = {
        list = [
          "bloodwolfe"
          "systemd-boot"
        ] ++ require-nixos;
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
      networking.hostName = "iso";
      #services.resolved.enable = true;

      environment.systemPackages = with pkgs; [
        hello
      ];
      #users.users."bloodwolfe".hashedPassword = lib.mkForce "";
    };
}
