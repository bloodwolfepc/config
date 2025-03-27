{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "steam";
    hardware.steam-hardware.enable = true;
    programs.steam = {
      enable = true;
      platformOptimizations.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession = { 
      enable = true;
        args = [ ]; 
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin
        thcrap-steam-proton-wrapper
        steamtinkerlaunch
      ];
      extraPackages = with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        mangohud
        gamescope
      ];
    };
    packages = with pkgs; [
      steamcmd
      steam-run
      protonup-ng
      protontricks
      #vkbasalt
      #vkbasalt-cli
      #steamtinkerlaunch #WARN: https://github.com/NixOS/nixpkgs/issues/210018
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
