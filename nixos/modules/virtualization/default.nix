{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkConfig {
    name = "virtualisation";
    packages = with pkgs; [
      distrobox
      podman-tui
      dive
      qemu
    ];
    virtualisation = {
      containers.enable = true;
      oci-containers.backend = "podman";
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true; # tpm emulator
          ovmf.enable = true; # UEFI
        };
      };
      waydroid.enable = true;
    };
    services.rkvm = {
      enable = false;
    };
    programs.virt-manager = {
      enable = true;
    };
    persistDirs = [
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
