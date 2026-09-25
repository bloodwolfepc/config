{
  config,
  pkgs,
  ...
}:
let
  weztermConfig = config.dotfiles.source "wezterm/wezterm.lua" ./wezterm.lua;
in
{
  home.packages = [ pkgs.wezterm ];
  home.file.".config/wezterm/wezterm.lua".source = weztermConfig;
}
