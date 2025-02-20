{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "libresprite";
    packages = with pkgs; [
      libresprite
    ];
    syncDirs = [
      ".config/libresprite"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
