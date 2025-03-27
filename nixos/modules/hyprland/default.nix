{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "hyprland";
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };
    security.polkit.enable = true;
    xdg.portal = {
      enable = true;
    };
    programs.light.enable = true;
    programs.ydotool.enable = true;
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
