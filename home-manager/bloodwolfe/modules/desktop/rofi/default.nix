{
  lib,
  config,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.settings.windowrulev2 = [
    "stayfocused, class:(Rofi)"
  ];
  packages = with pkgs; [
    rofi-network-manager
    rofi-bluetooth
    rofi-power-menu
    rofi-pass
    (rofi-pulse-select.override {
      rofi-unwrapped = pkgs.rofi;
    })
    (rofi-systemd.override {
      rofi = pkgs.rofi;
    })
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    plugins = with pkgs; [
      rofi-emoji
      (rofi-calc.override {
        rofi-unwrapped = pkgs.rofi;
      })
      (rofi-top.override {
        rofi-unwrapped = pkgs.rofi;
      })
      (rofi-games.override {
        rofi = pkgs.rofi;
      })
      #rofi-mpd
      #rofi-vpn
      #rofi-file-browser
    ];
  };
}
