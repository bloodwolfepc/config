{ lib, config, pkgs, ... }: let #TODO toggle command
  attrs = lib.custom.mkHomeApplication {
    name = "waybar";
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
      settings = {
        mainBar = {
          reload_style_on_change = true;
          layer = "top";
          position = "top";
          height = 22;
          modules-left = [ "hyprland/submap" "hyprland/scratchpad" "hyprland/window" ];
          modules-center = [ "image#album-art" "mpris" "custom/lyrics" ];
          modules-right = [ "gamemode"  "network" "cpu" "memory" "battery" "clock#date" "clock" ];

          mpris = {
          interval = 1;
            format = "{position}:{artist} - {album} - {title}";
          };

          #"custom/lyrics" = {
          #  interval = 1;
          #  format = "{}";
          #  exec = "echo $(tail -n 1 /tmp/lyrics.txt)";
          #};

          gamemode = {
            interval = 1;
            format = "gm={count}";
          };
          network = {
            interval = 1;
            format = "^{bandwidthUpBits} v{bandwidthDownBits}";
          };
          wireplumber = {
            interval = 1;
            format = "{volume}";
          };
          cpu = {
            interval = 1;
            format = "cpu: {load}";
          };
          memory = {
            interval = 1;
            format = "mem: {used}";
          };
          clock = {
            interval = 1;
            format = "{:%H:%M:%S}";
          };
          "clock#date" = {
            interval = 1;
            format = "{:%Y:%m:%d}";
          };
        };
      };
    };
    home.activation.waybar-copy-style-css = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.config/waybar/style.css" ]; then
        touch "$HOME/.config/waybar/style.css"
        chmod u+w "$HOME/.config/waybar/style.css"
        cp ${./style.css} "$HOME/.config/waybar/style.css"
      fi
    '';
    pcExtraConfig = ''
      submap = TOGGLE
        bindi = , w , exec , systemctl stop --user waybar.service || systemctl start --user waybar.service
        bindi = , e , exec , systemctl start --user waybar.service
      submap = escape
    '';
    stylix.targets.waybar.enable = false;
    inherit config;
  };
in {
  inherit (attrs) options config;
}
