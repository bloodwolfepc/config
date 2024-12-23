{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "hyfetch";
    inherit config;
    programs.hyfetch = {
      enable = true;
      settings = {
        preset = "transgender";
        mode = "rgb";
        color_align = {
          mode = "horizontal";
        };
      };
    };
  };
in {
  inherit (attrs) options config;
}
