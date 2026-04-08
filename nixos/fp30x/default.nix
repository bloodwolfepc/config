{ inputs, ... }:
{
  imports = [
    inputs.hardware.nixosModules.raspberry-pi-5
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../modules/users/bloodwolfe
    ../modules/impermanence
    ../modules/kanata.nix
    ../modules/nix.nix
    ../modules/security.nix
    ../modules/hyprland.nix
  ];

  boot.initrd.systemd.emergencyAccess = true;

  networking = {
    hostName = "fp30x";
    useDHCP = true;
  };
  #nixpkgs.config.allowUnsupportedSystem = true;
}
