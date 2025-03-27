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
      bindi = , BRACKETLEFT, togglefloating
      bindi = , v, fullscreen
      bindi = , x, killactive
    submap = escape
    submap = POSITION
      bindi = , ${config.kb_RIGHT}, movewindow, r
      bindi = , ${config.kb_DOWN}, movewindow, d
      bindi = , ${config.kb_UP}, movewindow, u
      bindi = , ${config.kb_LEFT}, movewindow, l
      bindi = , BRACKETRIGHT, centerwindow
    submap = escape
    submap = RESIZE
      bindm = ,mouse:272, movewindow
      bindm = ,mouse:273, resizewindow
      bindi = ,${config.kb_LEFT}, resizeactive, -50 0
      bindi = ,${config.kb_DOWN}, resizeactive, 0 50
      bindi = ,${config.kb_UP}, resizeactive, 0 -50
      bindi = ,${config.kb_RIGHT}, resizeactive, 50 0
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
