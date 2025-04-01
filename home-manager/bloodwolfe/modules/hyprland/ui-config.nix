#TODO: bind that toggle both gaps and bar
{ config, lib, pkgs, ... }: let
  hy3 = config.hl-plugins.hy3; #config.configured.hyprland.plugins.hy3; 
  split-monitor-workspaces = config.hl-plugins.split-monitor-workspaces; #config.configured.hyprland.plugins.split-monitor-workspaces; 
  hyprland = {
    settings = {
      general = {
        layout = (lib.mkIf hy3.enable (lib.mkForce "hy3"));
      };
      plugin = lib.mkMerge [
        { hy3 = lib.mkIf hy3.enable { }; }
        {
          split-monitor-workspaces = lib.mkIf split-monitor-workspaces.enable {
            count = 10;
            keep_focused = 1;
            enable_notifications = 1;
            enable_persistent_workspaces = 1;
          };
        }
      ];
    };
    extraConfig = let
      movewindow = if hy3.enable then "hy3:movewindow" else "movewindow";
      movefocus = if hy3.enable then "hy3:movefocus" else "movefocus";
      makegroup = if hy3.enable then "hy3:makegroup" else "null";
      changegroup = if hy3.enable then "hy3:changegroup" else "null";
      workspace = if split-monitor-workspaces.enable then "split-workspace" else "workspace";
      movetoworkspace = if split-monitor-workspaces.enable then "split-movetoworkspace" else "movetoworkspace";
      movetoworkspacesilent = if split-monitor-workspaces.enable then "split-movetoworkspacesilent" else "movetoworkspacesilent";
      const = ''
        bindm = , mouse:272, ${movewindow}
        bindm = , mouse:273, resizewindow
        bindi = , f, togglefloating
        bindi = , c, centerwindow
      '';
      resize-value = "200";
      lesser-resize-value = "50";
      mov-value = resize-value;
      lesser-mov-value = lesser-resize-value;
      resize = lib.mkShellScriptBin (builtins.readFile ./sh/resize.sh);
      move = lib.mkShellScriptBin (builtins.readFile ./sh/move.sh);
    in lib.mkBefore ''
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
        
        bindm = , mouse:272, ${movewindow}
        bindm = , mouse:273, resizewindow

        bindi = , ${config.kb_RIGHT}, ${movefocus}, r
        bindi = , ${config.kb_DOWN}, ${movefocus}, d
        bindi = , ${config.kb_UP}, ${movefocus}, u
        bindi = , ${config.kb_LEFT}, ${movefocus}, l
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

      submap = RESIZE
        ${const}
        bindi = , m, submap, MOV 
        bindie = , ${config.kb_RIGHT}, exec, ${resize} h
        bindie = , ${config.kb_DOWN}, exec, ${resize} j
        bindie = , ${config.kb_UP}, exec, ${resize} k
        bindie = , ${config.kb_LEFT}, exec, ${resize} l
        bindie = , n, exec, ${resize} n
        bindie = , p, exec, ${resize} p
      submap = escape
      submap = MOV
        ${const}
        bindi = , ${config.kb_RESIZE}, submap, RESIZE
        bindie = , ${config.kb_RIGHT}, exec, ${move} h
        bindie = , ${config.kb_DOWN}, exec, ${move} j
        bindie = , ${config.kb_UP}, exec, ${move} k
        bindie = , ${config.kb_LEFT}, exec, ${move} l
        #binde = , Shift_L ,${config.kb_RIGHT}, ${movewindow}, r
        #binde = , Shift_L ,${config.kb_DOWN}, ${movewindow}, d
        #binde = , Shift_L ,${config.kb_UP}, ${movewindow}, u
        #binde = , Shift_L ,${config.kb_LEFT}, ${movewindow}, l
      submap = escape

      submap = REC
        bindi = , c, exec, ${pkgs.grimblast}/bin/grimblast copy area
      submap = escape

      submap = TOGGLE
        bindi = , g, exec, hyprctl --batch "keyword general:gaps_out 0" & hyprctl --batch "keyword general:gaps_in 0" || hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
        bindi = , h, exec, hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
      submap = escape
    '';      
  };
in {
  inherit hyprland;
}
