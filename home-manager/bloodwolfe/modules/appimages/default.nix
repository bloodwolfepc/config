{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "appimages";
    packages = with pkgs; [
      appimage-run
    ];
    syncDirs = [
      "appimages"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
