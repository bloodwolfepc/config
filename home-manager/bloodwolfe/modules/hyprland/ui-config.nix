#TODO: bind that toggle both gaps and bar, swapwindow bind
#https://github.com/Zerodya/hyprfreeze
#monitor transform binds? monitor = eDP-1, 2880x1800@90, 0x0, 1, transform, 1

#TODO: dpms script (actually may need to be an enable/disable script):
#$1 is the monitor to toggle dpms state and $2 is where the workspaces are sent and merged
#if $2 is not given then reserve those workspaces, although they will not be accessible (of maybe send them somewhere particular)

#hyprctl keyword monitor "eDP-1, disable"

{
  config,
  lib,
  pkgs,
  ...
}:
let
  hy3 = config.hl-plugins.hy3; # config.configured.hyprland.plugins.hy3;
  hyprsplit = config.hl-plugins.hyprsplit;
  split-monitor-workspaces = config.hl-plugins.split-monitor-workspaces; # config.configured.hyprland.plugins.split-monitor-workspaces;
  hyprland = {
    settings = {
      general = {
        layout = (lib.mkIf hy3.enable (lib.mkForce "hy3"));
      };
      plugin = lib.mkMerge [
        { hy3 = lib.mkIf hy3.enable { }; }
        #{
        #  split-monitor-workspaces = lib.mkIf split-monitor-workspaces.enable {
        #    count = 10;
        #    keep_focused = 1;
        #    enable_notifications = 0;
        #    enable_persistent_workspaces = 1;
        #  };
        #}
        {
          hyprsplit = {
            num_workspaces = 10;
            persistent_workspaces = true;
          };
        }
      ];
    };
    extraConfig =
      let
        menu = "${pkgs.rofi-wayland}/bin/rofi";
        movewindow = if hy3.enable then "hy3:movewindow" else "movewindow";
        movefocus = if hy3.enable then "hy3:movefocus" else "movefocus";
        #makegroup = if hy3.enable then "hy3:makegroup" else "null";
        #changegroup = if hy3.enable then "hy3:changegroup" else "null";
        workspace = if hyprsplit.enable then "split:workspace" else "workspace";
        movetoworkspace = if hyprsplit.enable then "split:movetoworkspace" else "movetoworkspace";
        movetoworkspacesilent =
          if hyprsplit.enable then "split:movetoworkspacesilent" else "movetoworkspacesilent";
        const = ''
          bindm = , mouse:272, ${movewindow}
          bindm = , mouse:273, resizewindow
          bindi = , f, togglefloating
          bindi = , c, centerwindow
        '';
        hl-util = pkgs.writeShellScriptBin "hl-util.sh" (builtins.readFile ./sh/hl-util.sh);
      in
      lib.mkBefore ''
        submap = INS
          bind = , SUPER_L, submap, NML
        submap = escape

        submap = NML
          bindi = , i, submap, INS
          bindi = , e, submap, EXEC
          bindi = , f, submap, WS
          bindi = , d, submap, DEPLOY
          bindi = , r, submap, RESIZE
          bindi = , m, submap, MONITOR
          bindi = , comma, submap, SEND_TO_MONITOR
          bindi = , g, submap, MV->WS
          bindi = , c, submap, CONFIG
          bindi = , space, submap, MENU
          bindi = , o, submap, DROP
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
        submap = SEND_TO_MONITOR
          bind = , d, movecurrentworkspacetomonitor, 2
          bind = , f, movecurrentworkspacetomonitor, 1
          bind = , g, movecurrentworkspacetomonitor, 0
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
  };
in
{
  inherit hyprland;
}
