{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    podman-tui
    podman-desktop
    podman-compose
    distrobox
    distrobox-tui
  ];
  home.persistence."/persist/home/bloodwolfe".directories = [
    ".local/share/containers" # distrobox
  ];
  inherit config;
  services.podman = {
    enable = false;
  };
}
