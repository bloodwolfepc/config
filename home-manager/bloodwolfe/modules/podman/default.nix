{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "podman";
    packages = with pkgs; [
      podman-tui
      podman-desktop
      podman-compose
      distrobox
      distrobox-tui
    ];
    persistDirs = [
      ".local/share/containers" # distrobox
    ];
    inherit config;
    services.podman = {
      enable = true;
    };
  };
in
{
  inherit (attrs) options config;
}
