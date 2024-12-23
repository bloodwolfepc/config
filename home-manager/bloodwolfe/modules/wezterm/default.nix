{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "wezterm";
    key = "w";
    command = "${pkgs.wezterm}/bin/wezterm";
    programs.wezterm = {
      enable = true;
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
