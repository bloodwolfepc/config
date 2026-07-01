#TODO: zsh integration for pyprland and hyprland
#https://hyprland-community.github.io/pyprland/Commands.html
{
  pkgs,
  config,
  lib,
  ...
}@args:
lib.mkMerge [
  (import ./pyprland args)
  (import ./wayscriber args)
  (import ./swaync args)
  (import ./rofi args)
  (import ./waybar args)
  (import ./fcitx5 args)
  (import ./xdg args)
  (import ./font args)
  {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd = {
        enable = true;
        # extraCommands = lib.mkBefore [
        #   "systemctl --user stop graphical-session.target"
        #   "systemctl --user start hyprland-session.target"
        # ];
      };
      configType = "lua";
    };

    home.sessionVariables = {
      AQ_DRM_DEVICES = "/dev/dri/card1"; # /dev/dri/by-path/pci-0000:07:00.0-card
    };

    xdg = {
      enable = true;
      portal =
        let
          hyprland = config.wayland.windowManager.hyprland.package;
        in
        {
          enable = true;
          config.hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
          };
          extraPortals = [
            (pkgs.xdg-desktop-portal-hyprland.override { inherit hyprland; })
          ];
        };
    };

    home.packages = with pkgs; [
      (writeShellScriptBin "pc" ''
        ${hyprland}/bin/hyprland --config $FLAKE/hm-modules/hyprland/lua/hyprland.lua
      '')
      (writeShellScriptBin "toggle-touchpad" (builtins.readFile ./touchpad.sh))
      libnotify
      wayvnc
      wl-mirror
      grimblast
      grim
      slurp
      wl-clipboard
      xorg.xrandr
      hyprpicker
      imagemagick
      ueberzugpp
      pyprland
      wl-freeze
      wayscriber
    ];
    services.awww = {
      enable = true;
    };
    services.cliphist = {
      enable = true;
    };
    services.hyprpolkitagent.enable = true;
  }
]
