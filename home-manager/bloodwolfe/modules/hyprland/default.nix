
#TODO clipboard history management, screenshots
#command to toogle gaps
# bind that:
#moves firefox to a position of the aftive workspace and another to return it
#wvkbd-mobintl -L 400 -fn Unscii -bg 000000 -fg 000000 -fg-sp 000000 -press 000000|00 -press-sp 000000|00

{ lib, config, pkgs, ... }: let 
  modesetting = import ./modesetting.nix { inherit pkgs lib config; };
  attrs = lib.custom.mkHomeApplication {
    name = "hyprland";
    packages = with pkgs;[
      (writeShellScriptBin "pc" ''
        ${hyprland}/bin/Hyprland
      '')
      wayvnc
      swww
      wl-mirror
      grimblast
      wl-clipboard
      xorg.xrandr
    ]; 
    wayland.windowManager = let
      hyprland = import ./hyprland.nix { inherit pkgs lib config; };
      extraConfig = import ./extra-config.nix { inherit pkgs lib config; };
    in lib.mkMerge [
      { hyprland = hyprland.attrs; }
      { hyprland.extraConfig = lib.mkBefore extraConfig.attrs.extraConfig; }
      { hyprland.extraConfig = lib.mkAfter modesetting.attrs.extraConfig; }
    ];
    xdg = {
      enable = true;
      portal = let
        hyprland = config.wayland.windowManager.hyprland.package;
      in {
        enable = true;
        configPackages = [
          hyprland
        ];
        extraPortals = with pkgs; [ 
          xdg-desktop-portal-hyprland
	        xdg-desktop-portal-wlr
	        xdg-desktop-portal-gtk
        ];
      };
    };
    inherit config;
    inherit extraOptions;
  };
  extraOptions = modesetting.options;

in {
  inherit (attrs) options config;
}
