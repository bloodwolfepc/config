{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "btop";
    inherit config;
    programs.btop = {
      enable = true;
    };
  }; 
in {
  inherit (attrs) options config;
}
