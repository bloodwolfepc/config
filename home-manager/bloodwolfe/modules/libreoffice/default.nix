{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "libreoffice";
    packages = with pkgs; [
      libreoffice-qt
      hunspell
      hunspellDicts.en_US
    ];
    syncDirs = [
      ".config/libreoffice"
    ];
    inherit config;
  };
in {
  inherit (attrs) options config;
}
