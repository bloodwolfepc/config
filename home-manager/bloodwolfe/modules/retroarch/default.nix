{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "retroarch";
    command = "${pkgs.retroarchFull}/bin/retroarch";
    packages = with pkgs; [
      (retroarch.withCores (cores: with cores; [
        play
        swanstation
        pcsx-rearmed
        beetle-psx
        snes9x
        pcsx2
        dolphin
        desmume
        bsnes
        nxengine
        dosbox
      ]))
      retroarch-assets
      retroarch-joypad-autoconfig
    ];
    syncDirs = [
      ".config/retroarch"
      "games"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
