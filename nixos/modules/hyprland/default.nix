{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  attrs = lib.custom.mkConfig {
    name = "hyprland";
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    security.polkit.enable = true;
    xdg.portal = {
      enable = true;
    };
    programs.light.enable = true;
    programs.ydotool.enable = true;
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
