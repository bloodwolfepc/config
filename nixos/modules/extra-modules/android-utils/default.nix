{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "android-utils";
    programs.adb.enable = true;
    packages = with pkgs; [ 
      universal-android-debloater 
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
