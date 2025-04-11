{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "rofi";
    key = "space";
    command = "${pkgs.rofi}/bin/rofi -show run";
    pcWindowRule = [
      "stayfocused, class:(Rofi)"
    ];
    packages = with pkgs; [
      rofi-network-manager
      rofi-bluetooth
      rofi-power-menu
      rofi-pass-wayland
      (rofi-pulse-select.override {
        rofi-unwrapped = pkgs.rofi-wayland-unwrapped;
      })
      (rofi-systemd.override {
        rofi = pkgs.rofi-wayland-unwrapped;
      })
    ];

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      terminal = "${pkgs.alacritty}/bin/alacritty";
      plugins = with pkgs; [
        rofi-emoji-wayland
        (rofi-calc.override {
          rofi-unwrapped = pkgs.rofi-wayland-unwrapped;
        })
        (rofi-top.override {
          rofi-unwrapped = pkgs.rofi-wayland-unwrapped;
        })
        (rofi-games.override {
          rofi = pkgs.rofi-wayland-unwrapped;
        })
        #rofi-mpd
        #rofi-vpn
        #rofi-file-browser
      ];
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
