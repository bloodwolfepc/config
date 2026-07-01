{
  pkgs,
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
  home.packages = with pkgs; [
    waybar-lyric
  ];
  home.file.".config/waybar/config".source = ./config.json;
  home.file.".config/waybar/style.css".source = ./style.css;
}
