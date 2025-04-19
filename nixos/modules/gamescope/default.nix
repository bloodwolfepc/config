#TODO: have two execs, one with and and other without args

{ lib, config, pkgs, inputs, ... }: let
  attrs = lib.custom.mkConfig {
    name = "gamescope";
    #programs.gamescope = {  
    #  enable = true;
    #  #capSysNice = true; #BROKEN in steam: https://github.com/NixOS/nixpkgs/issues/208936
    #};
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}

#args = [
#   "--output-width 1920"
#   "--output-height 1080"
#   "--nested-width 1920"
#   "--nested-height 1080"
#   "--nested-refresh 144"
#   "--nested-unfocused-refresh 144"
#   
#   #"--prefer-output DP-1"
#   "--immediate-flips"
#   "--rt"
#   "--expose-wayland"
#   #"--borderless"
#   #"--fullscreen"
#   #"--stats-path /tmp/gamescopelog"
#   #"--mangoapp"
#   "--backend sdl" #will break without
#   "--steam"
#   #"--filter fsr"
#   #"--scaler auto"
#   #"--sdr-gamut-wideness 1"
#   #"--hdr-enabled"
#   #"--adaptive-sync"
#   #"--force-grab-cursor"
#];
