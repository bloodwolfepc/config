{ lib, config, pkgs, ... }: let #TODO toggle command
  attrs = lib.custom.mkHomeApplication {
    name = "waybar";
    pcExtraConfig = ''
      submap = TOGGLE
        bindi = , w , exec , systemctl stop --user waybar.service || systemctl start --user waybar.service
        bindi = , e , exec , systemctl start --user waybar.service
      submap = escape
    '';
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
      settings = {
        mainBar = {
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
      style =
        ''
        * {
          border: none;
          border-radius: 0;
          font-family: unscii;
        }  
        window#waybar {
          background: #000000;
          border-bottom: 2px solid #f0ffff;
        }
        #window {
          color: #f0ffff;
        }
        #custom-lyrics {
          color: cyan;
          border-left-style: solid;
          border-left-width: 3px;
          border-left-color: white;
          border-right-style: solid;
          border-right-width: 2px;
          border-right-color: white;
          padding-left: 1em;
          padding-right: 1em;
        }
        #mpris, #clock, #clock#date, #battery, #memory, #cpu, #network, #wireplumber {
          color: #f0ffff;
          border-left-style: solid;
          border-left-width: 1px;
          border-left-color: #f0ffff;
          padding-left: 0.7em;
          padding-right: 0.4em;
          padding-top: 0.4em
        }
      '';
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
