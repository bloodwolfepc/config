{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication rec {
    name = "alacritty";
    command = "${pkgs.alacritty}/bin/alacritty";
    key = "t"; 
    pcExecOnce = [
      "${command}"
      "swaync --inhibitor-add Alacritty" #block spotify_player
    ];
    programs.alacritty = {
      enable = true;
      settings = {
      	font = {
          size = lib.mkForce 12.0;
      		normal.family = lib.mkForce "unscii";
      		normal.style = lib.mkForce "16-full";
          italic.family = lib.mkForce "unscii";
          italic.style = lib.mkForce "16-full";
          bold_italic.family = lib.mkForce "unscii";
          bold_italic.style = lib.mkForce "16-full";
          bold.family = lib.mkForce "unscii";
          bold.style = lib.mkForce "16-full";
      	};
      	window = {
      		opacity = lib.mkForce 0.0;
      		blur = lib.mkForce false;
        };
        colors.normal = {
          black = lib.mkForce "0x181818";
          red = lib.mkForce "0xFF0000";
          green = lib.mkForce "0x00FF00";
          yellow = lib.mkForce "0xFFFF00";
          blue = lib.mkForce "0x0000FF";
          magenta = lib.mkForce "0xFF00FF";
          cyan = lib.mkForce "0x00FFFF";
          white = lib.mkForce "0xFFFFFF";
      	};
      };
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
