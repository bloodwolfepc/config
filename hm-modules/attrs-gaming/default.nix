{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.wl-crosshair.packages.${pkgs.system}.default
  ];

  # mangohud/
  # prismlauncher/
  # retroarch/
  # steam/
}
