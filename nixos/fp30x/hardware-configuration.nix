{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "ext4";
  #   options = [ "noatime" ];
  # };

  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  fileSystems = {
    "/" = {
      device = "/dev/root_vg/root";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };
    "/persist" = {
      device = "/dev/root_vg/root";
      fsType = "btrfs";
      options = [ "subvol=persist" ];
    };
    "/nix" = {
      device = "/dev/root_vg/root";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/B043-58C2";
      fsType = "vfat";
    };
  };
}
