{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    wezterm
    (pkgs.writeShellScriptBin "src-wezterm" ''
      wezterm --config-file $FLAKE/hm-modules/wezterm/wezterm.lua start --class src-wezterm $@
    '')
  ];
  home.file.".config/wezterm/wezterm.lua".source = ./wezterm.lua;
}
