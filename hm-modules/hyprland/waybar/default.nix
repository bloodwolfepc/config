{
  pkgs,
  inputs,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };
  home.packages = [
    inputs.waybar-lyric.packages.${pkgs.system}.default
  ];
  home.file.".config/waybar/config".source = ./config.jsonc;
  home.file.".config/waybar/style.css".source = ./style.css;
}
