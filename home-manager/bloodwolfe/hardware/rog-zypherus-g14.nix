{ lib, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    input.touchpad = {
      natural_scroll = false;
      disable_while_typing = false;
    };
  };
}
