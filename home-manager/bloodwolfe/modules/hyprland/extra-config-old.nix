#TODO: bind that toggle both gaps and bar
{ config, lib, pkgs, ... }: let
  attrs.extraConfig = ''
    submap = INS
      bind = , ${config.kb_NML}, submap, NML
    submap = escape

    submap = NML
      bindi = ,${config.kb_INS}, submap, INS
      bindi = ,${config.kb_EXEC}, submap, EXEC
      bindi = ,${config.kb_WS}, submap, WS
      bindi = ,${config.kb_DEPLOY}, submap, DEPLOY
      bindi = ,${config.kb_MIGRATE}, submap, MIGRATE
      bindi = ,${config.kb_POSITION}, submap, POSITION
      bindi = ,${config.kb_RESIZE}, submap, RESIZE
      bindi = ,${config.kb_REC}, submap, REC
      bindi = ,${config.kb_MONITOR}, submap, MONITOR
      bindi = ,${config.kb_CONFIG}, submap, CONFIG
      bindi = ,${config.kb_TOGGLE}, submap, TOGGLE
      
      bindm = , mouse:272, movewindow
      bindm = , mouse:273, resizewindow
      bindi = , ${config.kb_RIGHT}, movefocus, r
      bindi = , ${config.kb_DOWN}, movefocus, d
      bindi = , ${config.kb_UP}, movefocus, u
      bindi = , ${config.kb_LEFT}, movefocus, l
      bindi = , v, fullscreen
      bindi = , x, killactive
      binde = Shift_L, n, cyclenext
      binde = Shift_L, n, bringactivetotop
      binde = Shift_L, p, focuscurrentorlast
      binde = Shift_L, p, bringactivetotop
    submap = escape

    submap = WS
      bindi = , a, workspace, 1
      bindi = , s, workspace, 2
      bindi = , d, workspace, 3
      bindi = , f, workspace, 4
      bindi = , g, workspace, 5
      bindi = , h, workspace, 6
      bindi = , j, workspace, 7
      bindi = , k, workspace, 8
      bindi = , l, workspace, 9
      bindi = , semicolon, workspace, 10

      bindi = , n, workspace, +1
      bindi = , p, focuscurrentorlast
    submap = escape

    submap = RESIZE
      bindm = , mouse:272, movewindow
      bindm = , mouse:273, resizewindow
      bindie = , ${config.kb_LEFT}, resizeactive, -200 0
      bindie = , ${config.kb_DOWN}, resizeactive, 0 200
      bindie = , ${config.kb_UP}, resizeactive, 0 -200
      bindie = , ${config.kb_RIGHT}, resizeactive, 200 0
      # binde = Shift_L, ${config.kb_LEFT}, resizeactive, -100 0
      # binde = Shift_L, ${config.kb_DOWN}, resizeactive, 0 100
      # binde = Shift_L, ${config.kb_UP}, resizeactive, 0 -100
      # binde = Shift_L, ${config.kb_RIGHT}, resizeactive, 100 0
      # binde = Control_L, ${config.kb_LEFT}, moveactive, -200 0
      # binde = Control_L, ${config.kb_DOWN}, moveactive, 0 200
      # binde = Control_L, ${config.kb_UP}, moveactive, 0 -200
      # binde = Control_L, ${config.kb_RIGHT}, moveactive, 200 0
      # bindes = Control_L&Shift_L, ${config.kb_LEFT}, moveactive, -100 0
      # bindes = Control_L&Shift_L, ${config.kb_DOWN}, moveactive, 0 100
      # bindes = Control_L&Shift_L, ${config.kb_UP}, moveactive, 0 -100
      # bindes = Control_L&Shift_L, ${config.kb_RIGHT}, moveactive, 100 0

      bindi = Alt_L, ${config.kb_RIGHT}, movewindow, r
      bindi = Alt_L, ${config.kb_DOWN}, movewindow, d
      bindi = Alt_L, ${config.kb_UP}, movewindow, u
      bindi = Alt_L, ${config.kb_LEFT}, movewindow, l

      bindi = , n, resizeactive, 200 200
      bindi = , p, resizeactive, -200 -200
      bindie = Shift_L, n, resizeactive, 100 100
      bindie = Shift_L, p, resizeactive, -100 -100

      bindie = , f, togglefloating
      bindie = , c, centerwindow
    submap = escape

    submap = REC
      bindi = , c, exec, ${pkgs.grimblast}/bin/grimblast copy area
    submap = escape

    submap = TOGGLE
      bindi = , g, exec, hyprctl --batch "keyword general:gaps_out 0" & hyprctl --batch "keyword general:gaps_in 0" || hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
      bindi = , h, exec, hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
    submap = escape
  '';      
in {
  inherit attrs;
}
