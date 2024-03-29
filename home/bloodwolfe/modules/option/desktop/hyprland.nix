{ inputs, sonfig, pkgs, lib, ... }:
{
wayland.windowManager.hyprland = {
    enable = true;
    #systemd.enable = true;
    xwayland.enable = true;
    #plugins = [
    #  inputs.hyprland-plugins.packages."${pkgs.system}".hyprwinwrap
    #  inputs.hyprland-plugins.packages."${pkgs.system}".hyprtrails
    #];

    settings = {

	"monitor" = "DP-3, 1920x1080@144, 0x0, 1";

	"$wallpaper-path" = "~/flake/assets/wallpapers/Black.png";
	"$screenshot-path" = "~/Pictures/Snips/";
	    
	"$mode-insert" = "i";
	    "$mode-normal" = "SUPER_L";
		"$float" = "space";
		"$up" = "k";
		"$down" = "j";
	    	"$left" = "h";
	    	"$right" = "l";
	    	"$center" = "c";
	    	"$fullscreen" = "v";
		"$kill" = "x";
		"$command-bar-key" = "semicolon";
		#"$invert-transparency" = "0";
		"$mode-screentools" = "s";
	    	    "$screenshot-key" = "s";
	    	    "$full-screenshot-key" = "f";
	    	"$mode-exec" = "e";
	    	"$mode-term" = "t";
	    	"$mode-goto-workspace" = "f";
		"$mode-relocate-workspace" = "g";
		"$mode-move-window" = "m";
		"$mode-resize-window" = "r";

		"$pass-oneshots" = "/home/bloodwolfe/flake/scripts/pass-oneshots.conf";
		"$submap-reset" = "submap, INS";

	"$term" = "alacritty";
	"$menu" = "rofi -show run";
	"$screenshot" = "grimblast copysave area";
	"$full-screenshot" = "grimblast copysave screen";

	"bindi" = ", i, submap, INS";

    	general.allow_tearing = true;
	animations.enabled = false;

	dwindle = {
	    pseudotile = true;
	    preserve_split = true;
	    permanent_direction_override = true;
	};

	input = {
	    touchpad = {
		natural_scroll = false;
		disable_while_typing = false;
	    };
	    tablet = {
		transform = "6";
		region_size = "1920 1268";
	    };
	    kb_layout = "us";
	    follow_mouse = "1";
	    sensitivity = "0";
	    accel_profile = "flat";
	};
    };
    extraConfig = '' 	

	env = XCURSOR_SIZE,24
	env = QT_QPA_PLATFORMTHEME,qt6ct
	env = QT_QPA_PLATFORM=wayland;xcb
	env = GDK_BACKEND=wayland,x11
	env = SDL_VIDEODRIVER=wayland
	env = CLUTTER_BACKEND=wayland
	env = XDG_CURRENT_DESKTOP=sway
	env = XDG_DESSION_TYPE=wayland
	env = XDG_SESSION_DESKTOP=Hyprland
	env = WLR_DRM_NO_ATOMIC,1
	env = WLR_DRM_NO_ATOMIC,1




	exec-once = swaync
	exec-once = waybar
	exec-once = alacritty
	exec-once = polkit-kde-agent
	exec-once = wl-clipbard-history
	exec-once = swww init
	exec-once = hyprctl dispatch submap INS
	exec-once = /home/bloodwolfe/flake/lyrics.sh

	submap = INS
	    bind =, $mode-normal, submap, NML
	submap = escape

	submap = NML
	    bindi = ,$mode-insert, submap, INS
	    bindi = ,$mode-exec, submap, EXEC
	    bindi = ,$mode-term, submap, TERM
	    bindi = ,$mode-goto-workspace, submap, GLOBAL
	    bindi = ,$mode-relocate-workspace, submap, MIGRATE
	    bindi = ,$mode-move-window, submap, MOVE
	    bindi = ,$mode-resize-window, submap, RESIZE
	    bindi = ,$mode-screentools, submap, REC

	    bindi = ,$command-bar-key, exec, $menu
	    
	    bindm = ,mouse:272, movewindow
	    bindm = ,mouse:273, resizewindow
	    bindi = ,$left, movefocus, l
	    bindi = ,$right, movefocus, r
	    bindi = ,$up, movefocus, u
	    bindi = ,$down, movefocus, d
	    bindi = ,$float, togglefloating
	    bindi = ,$fullscreen, fullscreen
	    bindi = ,$kill, killactive
	    source = $pass-oneshots

	submap = escape
	submap = EXEC
	    bindi = ,$mode-insert, submap, INS
	    bindi = ,$mode-normal, submap, NML
	    bindi = ,$up, layoutmsg, preselect u
	    bindi = ,$down, layoutmsg, preselect d
	    bindi = ,$left, layoutmsg, preselect l
	    bindi = ,$right, layoutmsg, preselect r
	    bindi = ,$up, exec, $menu
	    bindi = ,$down, exec, $menu
	    bindi = ,$left, exec, $menu
	    bindi = ,$right, exec, $menu
	    bindi = ,$mode-exec, exec, $menu
	    source = $pass-oneshots
	submap = escape
	submap = TERM
	    bindi = ,$mode-insert, submap, INS
	    bindi =, $up, layoutmsg, preselect u
	    bindi =, $down, layoutmsg, preselect d
	    bindi =, $left, layoutmsg, preselect l
	    bindi =, $right, layoutmsg, preselect r
	    bindi =, $up, exec, e-normal$term
	    bindi =, $down, exec, $term
	    bindi =, $left, exec, $term
	    bindi =, $right, exec, $term
	    bindi =, $mode-term, exec, $term
	    bindi =, $mode-normal, submap, NML
	    source = $pass-oneshots
	submap = escape
	submap = GLOBAL
	    bindi = ,$mode-insert, submap, INS
	    bindi =, GRAVE, workspace, 1
	    bindi =, 1, workspace, 2
	    bindi =, 2, workspace, 3
	    bindi =, 3, workspace, 4
	    bindi =, 4, workspace, 5
	    bindi =, 5, workspace, 6
	    bindi =, 6, workspace, 7
	    bindi =, 7, workspace, 8 #i
	    bindi =, 8, workspace, 9 #i
	    bindi =, 9, workspace, 10 #i
	    bindi =, 0, workspace, 11 #i
	    bindi =, MINUS, workspace, 12 #i
	    bindi =, EQUAL, workspace, 13 #i
	    bindi =, q, workspace, 14
	    bindi =, w, workspace, 15
	    bindi =, e, workspace, 16
	    bindi =, r, workspace, 17
	    bindi =, t, workspace, 18
	    bindi =, y, workspace, 19
	    bindi =, u, workspace, 20 #i
	    bindi =, i, workspace, 21 #i
	    bindi =, o, workspace, 22 #i
	    bindi =, p, workspace, 23 #i
	    bindi =, BRACKETLEFT, workspace, 24 #i
	    bindi =, BRACKETRIGHT, workspace, 25 #i
	    bindi =, BACKSLASH, workspace, 26
	    bindi =, a, workspace, 27
	    bindi =, s, workspace, 28
	    bindi =, d, workspace, 29
	    bindi =, f, workspace, 30
	    bindi =, g, workspace, 31
	    bindi =, h, workspace, 32
	    bindi =, j, workspace, 33
	    bindi =, k, workspace, 34
	    bindi =, l, workspace, 35
	    bindi =, SEMICOLON, workspace, 36
	    bindi =, APOSTROPHE, workspace, 37
	    bindi =, z, workspace, 38
	    bindi =, x, workspace, 39
	    bindi =, c, workspace, 40
	    bindi =, v, workspace, 41
	    bindi =, b, workspace, 42
	    bindi =, n, workspace, 43
	    bindi =, m, workspace, 44
	    bindi =, COMMA, workspace, 45
	    bindi =, PERIOD, workspace, 46
	    bindi =, SLASH, workspace, 47
	    bindi =, $mode-normal, submap, NML
	    source = $pass-oneshots
	submap = escape
	submap = MIGRATE
	    bindi = ,$mode-insert, submap, INS
	    bindi =, GRAVE, movetoworkspace, 1
	    bindi =, 1, movetoworkspace, 2
	    bindi =, 2, movetoworkspace, 3
	    bindi =, 3, movetoworkspace, 4
	    bindi =, 4, movetoworkspace, 5
	    bindi =, 5, movetoworkspace, 6
	    bindi =, 6, movetoworkspace, 7
	    bindi =, 7, movetoworkspace, 8 #i
	    bindi =, 8, movetoworkspace, 9 #i
	    bindi =, 9, movetoworkspace, 10 #i
	    bindi =, 0, movetoworkspace, 11 #i
	    bindi =, MINUS, movetoworkspace, 12 #i
	    bindi =, EQUAL, movetoworkspace, 13 #i
	    bindi =, q, movetoworkspace, 14
	    bindi =, w, movetoworkspace, 15
	    bindi =, e, movetoworkspace, 16
	    bindi =, r, movetoworkspace, 17
	    bindi =, t, movetoworkspace, 18
	    bindi =, y, movetoworkspace, 19
	    bindi =, u, movetoworkspace, 20 #i
	    bindi =, i, movetoworkspace, 21 #i
	    bindi =, o, movetoworkspace, 22 #i
	    bindi =, p, movetoworkspace, 23 #i
	    bindi =, BRACKETLEFT, movetoworkspace, 24 #i
	    bindi =, BRACKETRIGHT, movetoworkspace, 25 #i
	    bindi =, BACKSLASH, movetoworkspace, 26
	    bindi =, a, movetoworkspace, 27
	    bindi =, s, movetoworkspace, 28
	    bindi =, d, movetoworkspace, 29
	    bindi =, f, movetoworkspace, 30
	    bindi =, g, movetoworkspace, 31
	    bindi =, h, movetoworkspace, 32
	    bindi =, j, movetoworkspace, 33
	    bindi =, k, movetoworkspace, 34
	    bindi =, l, movetoworkspace, 35
	    bindi =, SEMICOLON, movetoworkspace, 36
	    bindi =, APOSTROPHE, movetoworkspace, 37
	    bindi =, z, movetoworkspace, 38
	    bindi =, x, movetoworkspace, 39
	    bindi =, c, movetoworkspace, 40
	    bindi =, v, movetoworkspace, 41
	    bindi =, b, movetoworkspace, 42
	    bindi =, n, movetoworkspace, 43
	    bindi =, m, movetoworkspace, 44
	    bindi =, COMMA, movetoworkspace, 45
	    bindi =, PERIOD, movetoworkspace, 46
	    bindi =, SLASH, movetoworkspace, 47
	    bindi =, $mode-normal, submap, NML
	    source = $pass-oneshots
	submap = escape
	submap = MOVE
	    bindi = ,$mode-insert, submap, INS
	    bindi =, $up, movewindow, u
	    bindi =, $down, movewindow, d
	    bindi =, $left, movewindow, l
	    bindi =, $right, movewindow, r
	    bindi =, $center, centerwindow
	    bindi =, $mode-normal, submap, NML
	    source = $pass-oneshots
	submap = escape
	submap = RESIZE
	    bindi = ,$mode-insert, submap, INS
	    bindi =, $up, resizeactive, 0 -20
	    bindi =, $down, resizeactive, 0 20
	    bindi =, $left, resizeactive, -20 0
	    bindi =, $right, resizeactive, 20 0
	    bindi =, $mode-normal, submap, NML
	submap = escape
	submap = REC
	    bindi = ,$mode-insert, submap, INS
	    bindi =, $screenshot-key, exec, $screenshot FILE| $screenshot-path
	    bindi =, $full-screenshot-key, exec, $full-screenshot FILE| $screenshot-path
	    bindi =, $mode-normal, submap, NML
	    source = $pass-oneshots
	submap = escape
    '';

  };
}


