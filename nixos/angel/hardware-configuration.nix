{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  networking.useDHCP = lib.mkDefault true;
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
    "/sync" = {
      device = "/dev/root_vg/root";
      fsType = "btrfs";
      options = [ "subvol=sync" ];
    };
    "/home/bloodwolfe/.var/app" = {
      device = "/dev/root_vg/root";
      fsType = "btrfs";
      options = [ "subvol=flatpak" ];
    };
    "/boot" = { 
      device = "/dev/disk/by-uuid/B043-58C2";
      fsType = "vfat";
    };
  };
  swapDevices = [ 
    { device = "/dev/disk/by-uuid/4f4c5255-b471-4fb4-a8c2-644e9d3cd121"; }
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

