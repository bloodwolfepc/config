{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "htop";
    inherit config;
    programs.htop = {
      enable = true;
    };
  };
in {
  inherit (attrs) options config;
}
