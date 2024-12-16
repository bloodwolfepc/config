{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "spotify-player";
    persistDirs = [
      ".cache/spotify-player"
    ];
    inherit config;
    inherit extraConfig;
  }; 
  extraConfig = {
    programs.spotify-player = {
      enable = true;
      settings = {
        enable_notify = false;
        device = {
          name = "spotify-player";
          device_type = "speaker";
          volume = 80;
          bitrate = 320;
          audio_cache = false;
          normalization = false;
          copy_command = {
            command = "wl-copy"; #TODO if wayland wl-copy
            args = [];
          };
        };
      };
    };
  };
in {
  inherit (attrs) options config;
}
