#TODO: zsh integration for pyprland and hyprland
#https://hyprland-community.github.io/pyprland/Commands.html
{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./pyprland
    ./wayscriber
    ./swaync
    ./rofi
    ./waybar
    ./fcitx5.nix
    ./xdg.nix
    ./font.nix
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
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
        configPackages = [
          hyprland
        ];
        # config.hyprland = {
        #   default = [
        #     "termfilechooser"
        #     #"wlr"
        #     #"gtk"
        #   ];
        # };
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
      };
  };

  # .config/hypr/hyprland.lua
  home.packages = with pkgs; [
    (writeShellScriptBin "pc" ''
      ${hyprland}/bin/start-hyprland --config $FLAKE/home-manager/bloodwolfe/modules/hyprland/lua/hyprland.lua
    '')
    (writeShellScriptBin "toggle-touchpad" (builtins.readFile ./touchpad.sh))
    libnotify
    wayvnc
    wl-mirror
    grimblast
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
