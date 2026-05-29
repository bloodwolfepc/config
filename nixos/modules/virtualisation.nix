{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
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
        package = pkgs.qemu_kvm;
        # runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = with pkgs; [ virtiofsd ];
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
    "/var/lib/systemd" # https://github.com/NixOS/nixpkgs/issues/501336
  ];
  systemd.services.libvirtd.serviceConfig = {
    ReadOnlyPaths = [ "/var/lib/systemd/credential.secret" ];
  };
}
