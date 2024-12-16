{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "fd";
    inherit config;
    inherit extraConfig;
  }; 
  extraConfig = {
    programs.fd = {
      enable = true;
    };
  };
in {
  inherit (attrs) options config;
}