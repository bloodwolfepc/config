#for a working working clipboard
#wl-paste -t text -w xclip -selection clipboard
{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "wine";
    packages = with pkgs; [
      wineWowPackages.stagingFull
      winetricks
      #wineWowPackages.stable
      #wine
      #(wine.override { wineBuild = "wine64"; })
      #wine64
      #wineWowPackages.staging 
      #wineWowPackages.stagingFull
      #wineWowPackages.waylandFull 
    ];
    syncDirs = [
      "wine"
    ];
    pcExecOnce = [
      "wl-paste -t text -w xclip -selection clipboard" #fix for clipboard
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
