{
  config,
  pkgs,
  ...
}:
let
  weztermConfig = config.dotfiles.source "wezterm/wezterm.lua" ./wezterm.lua;
in
{
  home.packages = with pkgs; [
    wezterm
    (pkgs.writeShellScriptBin "src-wezterm" ''
      wezterm --config-file ${weztermConfig} start --class src-wezterm "$@"
    '')
  ];
  home.file.".config/wezterm/wezterm.lua".source = weztermConfig;
}
