{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../modules/users/bloodwolfe
    ../modules/impermanence
    ../modules/nix.nix
    ../modules/security.nix
    ./disko.nix
    # inputs.nixos-raspberrypi.nixosModules.raspberrypi-5.base
    # inputs.nixos-raspberrypi.nixosModules.raspberrypi-5.page-size-16k
    # inputs.nixos-raspberrypi.nixosModules.raspberrypi-5.display-vc4
    # inputs.nixos-raspberrypi.nixosModules.raspberrypi-5.display-rp1
    inputs.hardware.nixosModules.raspberry-pi-5
  ];
  networking = {
    hostName = "fp30x";
    interfaces.end0 = {
      ipv4.addresses = [
        {
          address = "192.168.5.2";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = "192.168.4.1";
        interface = "end0";
      };
      nameservers = [ "192.168.4.1" ];
    };
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    postBootCommands = ''
      mkdir /mnt
    '';
  };

  hardware.bluetooth.enable = true;
  services.colord.enable = false;

  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
  };
  time.timeZone = lib.mkDefault "America/Chicago";
}
