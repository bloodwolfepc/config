#TODO use a command field , redesign
#program = "${pkgs.rofi}/bin/rofi -show run";

{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "rofi";
    key = "e";
    command = "${pkgs.rofi}/bin/rofi -show run";
    pcWindowRule =  [
      "stayfocused , class:(Rofi)"
    ];
    programs.rofi = {
    	enable = true;
      package = pkgs.rofi-wayland-unwrapped;
    	#plugins = [
    	#  pkgs.rofi-emoji
    	#  pkgs.rofi-calc
    	#  pkgs.rofi-systemd
    	#];
    	terminal = "${pkgs.alacritty}/bin/alacritty";
    	location = "top";
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {	
      	"*" = {
      		#background-color = mkLiteral "#000000";
      	};
      	"#window" =  {
      		children = map mkLiteral [ "mainbox" ];
      		width = mkLiteral "100%";
      		height = mkLiteral "1.80%";
      	};
      	"#mainbox" = {
      		children = map mkLiteral [ "inputbar" ];
      		spacing = mkLiteral "0px";
      	};
      	"#inputbar" = {
      		children = map mkLiteral [ "entry" "listview"];
      		#spacing = mkLiteral "10px";
      	};
      	"#listview" = {
      		expand = mkLiteral "true";
      		dynamic = mkLiteral "true";
      		layout = mkLiteral "horizontal";
      		children = map mkLiteral [ "element" ];
      		columns = mkLiteral "3";
      		spacing = mkLiteral "2px";
      		lines = mkLiteral "20";
      		width = "80%";
      		margin = mkLiteral "0px";
      		border = mkLiteral "1px";
      		padding = mkLiteral "0px";
      		#font = "Unscii";
      	};
      	"#entry" = {
      		expand = mkLiteral "false";
      		placeholder = "";
      		#text-color = mkLiteral "#ffffff";
      		blink = mkLiteral "true";
      		width = mkLiteral "20%";
      		margin = mkLiteral "0px";
      		border = mkLiteral "1px";
      		padding = mkLiteral "0px";
      	};
      	"#element" = {
      		children = map mkLiteral [ "element-text" ];
      		orientation = mkLiteral "horizontal";
      		padding = mkLiteral "0px";
      		
      	};
      	"#element-text" = {
      		expand = mkLiteral "true";
      		#text-color = mkLiteral "#ffffff";
      	};
      };
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}

#{ config, lib, pkgs, ... }: let
#name = "rofi";
#program = "${pkgs.rofi}/bin/rofi -show run";
#bind = "e";
#in {
#
#  wayland.windowManager.hyprland = {
#    #settings.windowrulev2 = [ "stayfocused,class:(Rofi)" ];
#    extraConfig = lib.mkBefore ''
#      $focusRofi = & while [ "$(hyprctl clients | grep "class: Rofi")x" == "x" ]; do continue; done; hyprctl dispatch focuswindow "^(Rofi)"
#	    submap = EXEC
#        bindi = , ${bind}, submap ,EXEC_${name}
#	    submap = escape
#      submap = EXEC_${name}
#        bindi = , ${config.kb_INS}, submap, INS
#        bindi = , ${config.kb_NML}, submap, NML
#	      bindi = , ${config.kb_RIGHT}, layoutmsg, preselect r
#	      bindi = , ${config.kb_DOWN}, layoutmsg, preselect d
#	      bindi = , ${config.kb_UP}, layoutmsg, preselect u
#	      bindi = , ${config.kb_LEFT}, layoutmsg, preselect l
#	      bindi = , ${config.kb_RIGHT}, exec, ${program} $focusRofi
#	      bindi = , ${config.kb_DOWN}, exec, ${program} $focusRofi
#	      bindi = , ${config.kb_UP}, exec, ${program} $focusRofi
#	      bindi = , ${config.kb_LEFT}, exec, ${program} $focusRofi
#        source = $pass-oneshots
#      submap = escape
#      submap = EXEC_WS
#        bindi = , ${bind}, workspace, name:${name}
#        bindi = , ${bind}, exec, ${program}
#      submap = escape
#      submap = WS
#        bindi = , ${bind}, workspace, name:${name}
#      submap = escape
#    '';
#  };
#
#    home.packages = let
#      inherit (config.programs.password-store) package enable;
#    in
#      lib.optional enable (pkgs.pass-rofi.override {pass = package;});
#}
