{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };
  };
  home.packages = [
    inputs.waybar-lyric.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  home.file.".config/waybar/config".source =
    config.dotfiles.source "hyprland/waybar/config.jsonc" ./config.jsonc;
  home.file.".config/waybar/style.css".source =
    config.dotfiles.source "hyprland/waybar/style.css" ./style.css;
}
