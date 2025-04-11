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
            enable_notifications = 0;
            enable_persistent_workspaces = 1;
          };
        }
      ];
    };
    extraConfig = let
      menu = "${pkgs.rofi-wayland}/bin/rofi";
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
      hl-util = pkgs.writeShellScriptBin "hl-util.sh" (builtins.readFile ./sh/hl-util.sh);
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
        bindi = ,${config.kb_MONITOR}, submap, MONITOR
        bindi = , c, submap, CONFIG
        bindi = , space, submap, MENU
        bindi = , u, submap, UTILITY
        
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
        bindie = , ${config.kb_RIGHT}, exec, ${hl-util}/bin/hl-util.sh activewindow resize r
        bindie = , ${config.kb_DOWN}, exec, ${hl-util}/bin/hl-util.sh activewindow resize d 
        bindie = , ${config.kb_UP}, exec, ${hl-util}/bin/hl-util.sh activewindow resize u
        bindie = , ${config.kb_LEFT}, exec, ${hl-util}/bin/hl-util.sh activewindow resize l
        bindie = , n, exec, ${hl-util}/bin/hl-util.sh activewindow resize e
        bindie = , p, exec, ${hl-util}/bin/hl-util.sh activewindow resize c
      submap = escape
      submap = MOV
        ${const}
        bindi = , ${config.kb_RESIZE}, submap, RESIZE
        bindie = , ${config.kb_RIGHT}, exec, ${hl-util}/bin/hl-util.sh activewindow mv r
        bindie = , ${config.kb_DOWN}, exec, ${hl-util}/bin/hl-util.sh activewindow mv d
        bindie = , ${config.kb_UP}, exec, ${hl-util}/bin/hl-util.sh activewindow mv u
        bindie = , ${config.kb_LEFT}, exec, ${hl-util}/bin/hl-util.sh activewindow mv l
        #binde = , Shift_L ,${config.kb_RIGHT}, ${movewindow}, r
        #binde = , Shift_L ,${config.kb_DOWN}, ${movewindow}, d
        #binde = , Shift_L ,${config.kb_UP}, ${movewindow}, u
        #binde = , Shift_L ,${config.kb_LEFT}, ${movewindow}, l
      submap = escape

      submap = UTILITY
        bindi = , s, submap, SCREENSHOT
        bindi = , c, submap, COLOR
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
        bindi = , w, exec, ${hl-util}/bin/hl-util.sh grimblast setwallpaper area
        bindi = , e, exec, ${hl-util}/bin/hl-util.sh grimblast setwallpaper area fit
      submap = escape
      submap = MENU
        bindi = , space, exec, rofi -show run
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

      submap = CONFIG
        bindi = , g, exec, hyprctl --batch "keyword general:gaps_out 0" & hyprctl --batch "keyword general:gaps_in 0" || hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
        bindi = , h, exec, hyprctl --batch "keyword general:gaps_out 10" & hyprctl --batch "keyword general:gaps_in 4"
      submap = escape
    '';      
  };
in {
  inherit hyprland;
}
