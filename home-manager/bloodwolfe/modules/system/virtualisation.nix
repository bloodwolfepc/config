{
  config,
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
}
