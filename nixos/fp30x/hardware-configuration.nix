{ inputs, config, ... }:
{
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "usbhid"
      ];
    };
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      timeout = 5;
    };
  };
  nix.settings.auto-optimise-store = false;
  services.hardware.argonone.enable = true;

  nixpkgs.overlays = [
    (_: prev: { makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; }); })
  ];
  nixpkgs.hostPlatform.system = "aarch64-linux";
  powerManagement.cpuFreqGovernor = "powersave";

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
      device = "/dev/disk/by-uuid/CC46-177C ";
      fsType = "vfat";
    };
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/4f4c5255-b471-4fb4-a8c2-644e9d3cd121"; }
  ];
}
