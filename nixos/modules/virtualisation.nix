{
  pkgs,
  ...
}:
{
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
        swtpm.enable = true;
      };
    };
    waydroid.enable = false;
  };
  services.rkvm = {
    enable = false;
  };
  programs.virt-manager = {
    enable = true;
  };
  environment.persistence."/persist/system".directories = [
    "/var/lib/containers"
    "/var/lib/libvirt"
  ];
}
