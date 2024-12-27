{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "retroarch";
    #command = "${pkgs.retroarchFull}/bin/retroarch";
    #packages = with pkgs; [
    #  retroarchFull
    #  retroarch-assets
    #  retroarch-joypad-autoconfig
    #];
    syncDirs = [
      ".config/retroarch"
      "games"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
