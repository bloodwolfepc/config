{
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      podman-tui
      podman-desktop
      podman-compose
      distrobox
      distrobox-tui
    ];
    persistence."/persist".directories = [
      ".local/share/containers" # distrobox
    ];
  };

  services.podman = {
    enable = false;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
