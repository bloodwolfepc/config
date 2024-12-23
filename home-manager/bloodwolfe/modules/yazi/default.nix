{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "yazi";
    programs.yazi = {
      enable = true;
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
