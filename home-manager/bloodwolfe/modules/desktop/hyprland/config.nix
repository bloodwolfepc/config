{
  config,
  lib,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland.extraConfig =
    let
      movefocus = "movefocus";
      workspace = "workspace";
      movetoworkspace = "movetoworkspace";
      const = ''
        bindm = , mouse:272, movewindow
        bindm = , mouse:273, resizewindow
      '';
      hl-util = pkgs.writeShellScript "hl-util" (builtins.readFile ./sh/hl-util.sh);
      kb_right = "l";
      kb_down = "j";
      kb_up = "k";
      kb_left = "h";

      kb_nml = "super_l";
      kb_ins = "i";
      kb_ws = "f";
      kb_mvws = "g";
      kb_screenshot = "s";
      kb_menu = "space";
      kb_utility = "u";
      kb_reposition = "p";
      kb_monitor = "m";
      kb_sendtomonitor = "comma";
      kb_resize = "r";
    in
    lib.mkBefore ''
      submap = INS
        bind = , ${kb_nml}, submap, NML
      submap = escape

      submap = NML
        ${const}
        bindi = , ${kb_ins}, submap, INS
        bindi = , ${kb_ws}, submap, WS
        bindi = , ${kb_mvws}, submap, MV->WS
        bindi = , ${kb_screenshot}, submap, SCREENSHOT
        bindi = , ${kb_menu}, submap, MENU
        bindi = , ${kb_utility}, submap, UTILITY
        bindi = , ${kb_reposition}, submap, REPOSITION
        bindi = , ${kb_monitor}, submap, MONITOR
        bindi = , ${kb_sendtomonitor}, submap, SEND_TO_MONITOR
        bindi = , ${kb_resize}, submap, RESIZE
        bindi = , ${kb_right}, exec, ${hl-util} activewindow mvfocus r
        bindi = , ${kb_down}, exec, ${hl-util} activewindow mvfocus d
        bindi = , ${kb_up}, exec, ${hl-util} activewindow mvfocus u
        bindi = , ${kb_left}, exec, ${hl-util} activewindow mvfocus l
        binde = Shift_L, n, cyclenext
        binde = Shift_L, n, bringactivetotop
        binde = Shift_L, p, focuscurrentorlast
        binde = Shift_L, p, bringactivetotop
        bindi = , f, exec, hyprctl dispatch togglefloating
        bindi = , c, centerwindow
        bindi = , v, fullscreen
        bindi = , x, killactive
      submap = escape

      submap = WS
        ${const}
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
        ${const}
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
        bindie = , ${kb_right}, exec, ${hl-util} activewindow resize r
        bindie = , ${kb_down}, exec, ${hl-util} activewindow resize d 
        bindie = , ${kb_up}, exec, ${hl-util} activewindow resize u
        bindie = , ${kb_left}, exec, ${hl-util} activewindow resize l
        bindie = , n, exec, ${hl-util} activewindow resize e
        bindie = , p, exec, ${hl-util} activewindow resize c
      submap = escape

      submap = REPOSITION
        ${const}
        bindi = , s, submap, SWAPWINDOW 
        binde = , ${kb_right}, exec, ${hl-util} activewindow mv r
        binde = , ${kb_down}, exec, ${hl-util} activewindow mv d
        binde = , ${kb_up}, exec, ${hl-util} activewindow mv u
        binde = , ${kb_left}, exec, ${hl-util} activewindow mv l
      submap = escape

      submap = SWAPWINDOW
        ${const}
        bindi = , p, submap, REPOSITION 
         binde = , ${kb_right}, exec, ${hl-util} activewindow swap r
         binde = , ${kb_down}, exec, ${hl-util} activewindow swap d
         binde = , ${kb_up}, exec, ${hl-util} activewindow swap u
         binde = , ${kb_left}, exec, ${hl-util} activewindow swap l
      submap = escape

      submap = SCREENSHOT
        ${const}
        bindi = , s, exec, ${hl-util} ss copy area
        bindi = , a, exec, ${hl-util} ss copy window
        bindi = , f, exec, ${hl-util} ss copy all
        bindi = , w, exec, ${hl-util} ss setwallpaper area
        bindi = , e, exec, ${hl-util} ss setwallpaper area fit
      submap = escape

      submap = MENU
        ${const}
        bindi = , space, exec, ${hl-util} menu exec
        bindi = , f, exec, ${hl-util} menu cliphist
        bindi = , c, exec, ${hl-util} menu calc
        bindi = , e, exec, ${hl-util} menu emoji
        bindi = , t, exec, ${hl-util} menu top
        bindi = , w, exec, ${hl-util} menu clients
        bindi = , g, exec, ${hl-util} menu games
        bindi = , x, exec, ${hl-util} menu power
        bindi = , n, exec, ${hl-util} menu nmcli
        bindi = , b, exec, ${hl-util} menu bt
        bindi = , s, exec, ${hl-util} menu systemd
        bindi = , p, exec, ${hl-util} menu pass
        bindi = , bracketleft, exec, ${hl-util} menu audio-out
        bindi = , bracketright, exec, ${hl-util} menu audio-in
      submap = escape

      submap = UTILITY
        ${const}
        bindi = , f, exec, ${pkgs.hyprfreeze}/bin/hyprfreeze -a -s
        bindi = , o, exec, hdrop -f alacritty --class alacritty_drop
        bindi = , c, exec, ${hl-util} color
      submap = escape
    '';
}
