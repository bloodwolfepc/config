{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.extraConfig =
    let
      menu = "${pkgs.rofi-wayland}/bin/rofi";
      movewindow = "movewindow";
      movefocus = "movefocus";
      workspace = "workspace";
      movetoworkspace = "movetoworkspace";
      movetoworkspacesilent = "movetoworkspacesilent";
      resizewindow = "resizewindow";
      const = ''
        bindm = , mouse:272, ${movewindow}
        bindm = , mouse:273, resizewindow
        bindi = , f, togglefloating
        bindi = , c, centerwindow
      '';
      hl-util = pkgs.writeShellScriptBin "hl-util.sh" (builtins.readFile ./sh/hl-util.sh);
      kb_right = "l";
      kb_down = "j";
      kb_up = "k";
      kb_left = "h";
      kb_ins = "i";
      kb_nml = "super_l";
      kb_exec = "e";
      kb_ws = "f";
      kb_deploy = "d";
      kb_resize = "r";
      kb_monitor = "m";
      kb_sendtomonitor = "comma";
      kb_config = "s";
      kb_mvws = "g";
      kb_menu = "space";
      kb_drop = "o";
      kb_util = "u";
      kb_migrate = "g";
      kb_position = "o";
      kb_rec = "c";
      kb_toggle = "t";
    in
    lib.mkBefore ''
      submap = INS
        bind = , ${kb_nml}, submap, NML
      submap = escape

      submap = NML
        bindi = , ${kb_ins}, submap, INS
        bindi = , ${kb_exec}, submap, EXEC
        bindi = , ${kb_ws}, submap, WS
        bindi = , ${kb_deploy}, submap, DEPLOY
        bindi = , ${kb_resize}, submap, RESIZE
        bindi = , ${kb_monitor}, submap, MONITOR
        bindi = , ${kb_sendtomonitor}, submap, SEND_TO_MONITOR
        bindi = , ${kb_mvws}, submap, MV->WS
        bindi = , ${kb_config}, submap, CONFIG
        bindi = , ${kb_menu}, submap, MENU
        bindi = , ${kb_drop}, submap, DROP
        bindi = , ${kb_util}, submap, UTILITY
        
        bindm = , mouse:272, ${movewindow}
        bindm = , mouse:273, ${resizewindow}

        bindi = , ${kb_right}, ${movefocus}, r
        bindi = , ${kb_down}, ${movefocus}, d
        bindi = , ${kb_up}, ${movefocus}, u
        bindi = , ${kb_left}, ${movefocus}, l
        bindi = , v, fullscreen
        bindi = , x, killactive
        binde = Shift_L, n, cyclenext
        binde = Shift_L, n, bringactivetotop
        binde = Shift_L, p, focuscurrentorlast
        binde = Shift_L, p, bringactivetotop
      submap = escape

      submap = WS
        bindi = , a, ${workspace}, 1
        bindi = , s, ${workspace}, 2
        bindi = , d, ${workspace}, 3
        bindi = , f, ${workspace}, 4
        bindi = , g, ${workspace}, 5
        bindi = , h, ${workspace}, 6
        bindi = , j, ${workspace}, 7
        bindi = , k, ${workspace}, 8
        bindi = , l, ${workspace}, 9
        bindi = , semicolon, ${workspace}, 10
        bindi = , n, ${workspace}, +1
        bindi = , p, ${workspace}, -1
        binds = Shift_L, p, focuscurrentorlast
      submap = escape
      submap = MV->WS
        bindi = , a, ${movetoworkspace}, 1
        bindi = , s, ${movetoworkspace}, 2
        bindi = , d, ${movetoworkspace}, 3
        bindi = , f, ${movetoworkspace}, 4
        bindi = , g, ${movetoworkspace}, 5
        bindi = , h, ${movetoworkspace}, 6
        bindi = , j, ${movetoworkspace}, 7
        bindi = , k, ${movetoworkspace}, 8
        bindi = , l, ${movetoworkspace}, 9
        bindi = , semicolon, ${movetoworkspace}, 10
        bindi = , n, ${movetoworkspace}, +1
        bindi = , p, ${movetoworkspace}, -1
      submap = escape

      submap = RESIZE
        ${const}
        bindi = , m, submap, MOV 
        bindie = , ${kb_right}, exec, ${hl-util}/bin/hl-util.sh activewindow resize r
        bindie = , ${kb_down}, exec, ${hl-util}/bin/hl-util.sh activewindow resize d 
        bindie = , ${kb_up}, exec, ${hl-util}/bin/hl-util.sh activewindow resize u
        bindie = , ${kb_left}, exec, ${hl-util}/bin/hl-util.sh activewindow resize l
        bindie = , n, exec, ${hl-util}/bin/hl-util.sh activewindow resize e
        bindie = , p, exec, ${hl-util}/bin/hl-util.sh activewindow resize c
      submap = escape
      submap = MOV
        ${const}
        bindi = , ${kb_resize}, submap, RESIZE
        bindie = , ${kb_right}, exec, ${hl-util}/bin/hl-util.sh activewindow mv r
        bindie = , ${kb_down}, exec, ${hl-util}/bin/hl-util.sh activewindow mv d
        bindie = , ${kb_up}, exec, ${hl-util}/bin/hl-util.sh activewindow mv u
        bindie = , ${kb_left}, exec, ${hl-util}/bin/hl-util.sh activewindow mv l
        #binde = , Shift_L ,${kb_right}, ${movewindow}, r
        #binde = , Shift_L ,${kb_down}, ${movewindow}, d
        #binde = , Shift_L ,${kb_up}, ${movewindow}, u
        #binde = , Shift_L ,${kb_left}, ${movewindow}, l
      submap = escape

      submap = UTILITY
        bindi = , s, submap, SCREENSHOT
        bindi = , c, submap, COLOR
        bindi = , p, exec, hyprfreeze -a -s
        bindi = , r, exec, ${hl-util}/bin/hl-util.sh reset
      submap = escape

      submap = COLOR
        bindi = , c, exec, ${hl-util}/bin/hl-util.sh swaync recolor tmp
        bindi = , n, exec, ${hl-util}/bin/hl-util.sh swaync recolor
        bindi = , b, exec, ${hl-util}/bin/hl-util.sh waybar recolor
        bindi = , t, exec, ${hl-util}/bin/hl-util.sh waybar recolor text
        bindi = , w, exec, ${hl-util}/bin/hl-util.sh activewindow recolor
        bindi = , i, exec, ${hl-util}/bin/hl-util.sh activewindow recolor inactivebordercolor
        bindi = , p, exec, ${hl-util}/bin/hl-util.sh activewindow pinkspazz
        bindi = , space, exec, ${hl-util}/bin/hl-util.sh activewindow flash "#ff0000" "10" "0.05"
      submap = escape

      submap = SCREENSHOT
        bindi = , s, exec, ${hl-util}/bin/hl-util.sh grimblast screenshot area
        bindi = , a, exec, ${hl-util}/bin/hl-util.sh grimblast screenshot window
        bindi = , f, exec, ${hl-util}/bin/hl-util.sh grimblast screenshot all
        bindi = , w, exec, ${hl-util}/bin/hl-util.sh grimblast setwallpaper area
        bindi = , e, exec, ${hl-util}/bin/hl-util.sh grimblast setwallpaper area fit
      submap = escape

      submap = MENU
        bindi = , space, exec, rofi -show run
        bindi = , f, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
        bindi = , c, exec, rofi -modi calc -show calc -no-show-match -no-sort
        bindi = , e, exec, rofi -modi emoji -show emoji
        bindi = , t, exec, rofi -modi top -show top
        bindi = , w, exec, rofi -modi window -show window
        bindi = , g, exec, rofi -modi games -show games
        bindi = , x, exec, rofi -modi power-menu:rofi-power-menu -show power-menu
        bindi = , n, exec, rofi-network-manager
        bindi = , b, exec, rofi-bluetooth
        bindi = , s, exec, rofi-systemd
        bindi = , p, exec, rofi-pass
        bindi = , bracketleft, exec, rofi-pulse-select sink
        bindi = , bracketright, exec, rofi-pulse-select source
      submap = escape

      submap = DROP
        bindi = , o, exec, hdrop -f alacritty --class alacritty_drop
      submap = escape

      submap = CONFIG
        bindi = , g, exec, hyprctl --batch "keyword general:gaps_out 0" & hyprctl --batch "keyword general:gaps_in 0" || hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
        bindi = , h, exec, hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
      submap = escape
    '';
}
