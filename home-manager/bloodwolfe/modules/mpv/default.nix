{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "mpv";
    inherit config;
    programs.mpv = {
      enable = true;
      defaultProfiles = [
       "gpu-hq" #TODO if video acceleration is true
      ];
      config = {
        #cache-default = 4000000;
        ytdl-format = "bestvideo[height<=?1080][vcodec!*=av01]+bestaudio/best";
        profile = lib.mkDefault "gpu-hq";
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        slang = "en";
        sub-auto = "all";
        #fs = "yes";
        hwdec = "vaapi";
        vo = "gpu";
        gpu-context = "wayland"; #TODO if wayland is true
      };
    };
  }; 
in {
  inherit (attrs) options config;
}
