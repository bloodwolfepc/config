{ inputs, pkgs, ... }:
{
  imports = [
    ./steam.nix
    ./retroarch.nix
    ./prismlauncher.nix
    ./mangohud
  ];
  home.packages = [
    inputs.wl-crosshair.packages.${pkgs.system}.default
  ];
}
