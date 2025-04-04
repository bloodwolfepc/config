/*
  TODO:
  https://github.com/hyprwm/contrib/tree/main/hdrop
  https://github.com/Zerodya/hyprfreeze
  clipboard history management, screenshots
  command to toogle gaps
  bind that:
  moves firefox to a position of the aftive workspace and another to return it
  wvkbd-mobintl -L 400 -fn Unscii -bg 000000 -fg 000000 -fg-sp 000000 -press 000000|00 -press-sp 000000|00 
  monitor transform binds
    monitor = eDP-1, 2880x1800@90, 0x0, 1, transform, 1
  adsf are already reserved, new monitors should be given the rest of the homerow keys on assignment
  in normal mode s + hjkl will preset the direction of the next split and there should be visual indication
  auto assign keys to new monitors
*/

{ lib, config, pkgs, inputs, ... }: let 
  modesetting = import ./modesetting.nix { inherit pkgs lib config; };
  kb-globals = import ./kb-globals.nix { inherit pkgs lib config; };
  hyprland-attrs = import ./hyprland.nix { inherit pkgs lib config; };
  ui-config = import ./ui-config.nix { inherit pkgs lib config; };
  attrs = lib.custom.mkHomeApplication {
    name = "hyprland";
    packages = with pkgs;[
      (writeShellScriptBin "pc" ''
        ${hyprland}/bin/Hyprland
      '')
      libnotify
      (writeShellScriptBin "toggle-touchpad"
        (builtins.readFile ./sh/touchpad.sh)
      )
      (writeShellScriptBin "hl-util.sh"
        (builtins.readFile ./sh/hl-util.sh)
      )
      wayvnc
      wl-mirror
      grimblast
      wl-clipboard
      xorg.xrandr
      hyprpicker
      imagemagick
    ]; 
    services.swww.enable = true;
    wayland.windowManager.hyprland = lib.mkMerge [
      {
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      }
      { 
        plugins = [
          (lib.mkIf config.hl-plugins.hy3.enable inputs.hy3.packages.${pkgs.system}.hy3)
          (lib.mkIf config.hl-plugins.split-monitor-workspaces.enable inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces)
        ];
      }
      hyprland-attrs.attrs
      { inherit (modesetting.attrs) extraConfig; }
      { inherit (ui-config.hyprland) extraConfig settings; }
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
        config.hyprland = {
          #default = ["wlr" "gtk"];
        };
        extraPortals = with pkgs; [ 
	        xdg-desktop-portal-wlr
	        xdg-desktop-portal-gtk
        ];
      };
    };
    home.sessionVariables = {
      XCURSOR_SIZE = 24;
	    QT_QPA_PLATFORM = "wayland;xcb";
	    GDK_BACKEND= "wayland,x11";
	    SDL_VIDEODRIVER = "wayland";
	    CLUTTER_BACKEND = "wayland";
	    XDG_CURRENT_DESKTOP = "Hyprland";
	    XDG_DESSION_TYPE= "wayland";
	    XDG_SESSION_DESKTOP = "Hyprland";
	    WLR_DRM_NO_ATOMIC = 1;
      MOZ_ENABLE_WAYLAND = 1;
      AQ_DRM_DEVICES = "/dev/dri/card1";
      #"/dev/dri/by-path/pci-0000:07:00.0-card"
      HL_RESIZE = 100;
      HL_MOVE = 100;
    };
    inherit config;
    inherit extraOptions;
  };
  extraOptions = {
    hl-plugins = {
      hy3 = {
        enable = lib.mkEnableOption "Enable hy3.";
      };
      split-monitor-workspaces = {
        enable = lib.mkEnableOption "Enable split-monitor-workspaces.";
      };
    };
  } // kb-globals.options // modesetting.options;
in {
  inherit (attrs) options config;
}
