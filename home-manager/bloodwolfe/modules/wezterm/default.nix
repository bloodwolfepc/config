{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "wezterm";
    key = "w";
    command = "${pkgs.wezterm}/bin/wezterm";
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      #extraConfig = (builtins.readFile ./wezterm.lua);
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
