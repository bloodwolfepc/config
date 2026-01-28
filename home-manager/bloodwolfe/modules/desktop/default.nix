{ pkgs, ... }:
{
  imports = [
    ./hyprland
    ./swaync
    ./rofi
    ./waybar
    ./fcitx5.nix
    ./xdg.nix
  ];
  home.packages = with pkgs; [
    unscii
  ];
  fonts.fontconfig.enable = true;
}
