{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "feh";
    inherit config;
    programs.feh = {
      enable = true;
    };
  }; 
in {
  inherit (attrs) options config;
}
