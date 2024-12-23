{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "src";
    persistDirs = [
      "src"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
