#TODO: zsh integration for pyprland and hyprland
#https://hyprland-community.github.io/pyprland/Commands.html
{
  pkgs,
  config,
  ...
}:
let
  hyprlandConfig = config.dotfiles.source "hyprland/lua" ./lua;
in
{
  imports = [
    ./pyprland
    ./wayscriber
    ./swaync
    ./rofi
    ./waybar
    ./fcitx5
    ./xdg
    ./font
  ];

  config = {
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
      extraConfig = ''
        dofile("${hyprlandConfig}/hyprland.lua")
      '';
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
        ${hyprland}/bin/hyprland --config ${hyprlandConfig}/hyprland.lua
      '')
      (writeShellScriptBin "toggle-touchpad" (builtins.readFile ./touchpad.sh))
      (writeShellScriptBin "ocr-screenshot" (builtins.readFile ./ocr-screenshot.sh))
      tesseract
      libnotify
      wayvnc
      wl-mirror
      grimblast
      grim
      slurp
      wl-clipboard
      xrandr
      hyprpicker
      imagemagick
      ueberzugpp
      pyprland
      wl-freeze
      wayscriber
      (writeShellScriptBin "hyprvol" (builtins.readFile ./hyprvol.sh))
    ];
    services.awww = {
      enable = true;
    };
    services.cliphist = {
      enable = true;
    };
    services.hyprpolkitagent.enable = true;
  };
}
