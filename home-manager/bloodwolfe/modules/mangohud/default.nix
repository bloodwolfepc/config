{ lib, config, pkgs, ... }: let 
  inherit lib;
  attrs = lib.custom.mkHomeApplication {
    name = "mangohud";
    programs.mangohud = {
      enable = true;
      enableSessionWide = true;
      settings = lib.mkMerge [
        (lib.mkBefore {
          exec_name = 1;
          custom_text_center = "never knows best";
          fps = 1;
          no_display = true;
          output_folder = "${config.home.homeDirectory}/mangohud-logs";
          #toggle_hud = "F1";
          #toggle_hud_position = "F2";
          #toggle_logging = "F3";
          #reload_cfg = "F4";

        })
        (lib.mkAfter {
          time = 1;
          time_no_label = 1;
          time_format = "%T"; 
          gpu_stats = 1;
          cpu_stats = 1;
          vram = 1;
          ram = 1;
          frametime = lib.mkAfter 1;
          frame_timing = 1; #graph
          gpu_name = 1;
          vulkan_driver = 1;
          fsr = 1;
          debug = 1;
          hdr = 1;
          refresh_rate = 1;
          mangoapp_steam = 1;
          resolution = 1;
          network = 1;
        })
      ];
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}

