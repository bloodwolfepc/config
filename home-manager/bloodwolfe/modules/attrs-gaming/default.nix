{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.wl-crosshair.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # mangohud/
  # prismlauncher/
  # retroarch/
  # steam/
}
