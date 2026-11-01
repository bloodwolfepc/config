{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./firefox ];

  home.persistence = {
    "/persist".directories = [
      "programfiles"
      "src"
      "library"
      "qemu"

      ".cache/flatpak"
      ".config/kdeconnect"
      ".config/legcord"

      ".local/share/flatpak"
      ".local/state/wireplumber"

      ".local/share/zathura"
    ];
  };
  home.backups.legcord = {
    paths = [ ".config/legcord" ];
    exclude = map (name: "**/legcord/${name}") [
      "Cache"
      "Code Cache"
      "GPUCache"
      "Crashpad"
      "DawnGraphiteCache"
      "DawnWebGPUCache"
      "logs"
      "VideoDecodeStats"
      "WebrtcVideoStats"
      "SingletonCookie"
      "SingletonLock"
      "SingletonSocket"
      ".org.chromium.Chromium.*"
    ];
  };
  home.packages = with pkgs; [
    legcord

    #wineWowPackages.stagingFull
    winetricks

    xournalpp
    playerctl
    (pavucontrol.override { withLibcanberra = true; })
  ];
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  programs.mpv = {
    enable = true;
    defaultProfiles = [
      "gpu-hq"
    ];
    config = {
      ytdl-format = "bestvideo[height<=?1080][vcodec!*=av01]+bestaudio/best";
      profile = lib.mkDefault "gpu-hq";
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      slang = "en";
      sub-auto = "all";
      hwdec = "vaapi";
      vo = "gpu";
      gpu-context = "wayland";
    };
  };

  home.backups.state.paths = [
    ".local/share/zathura/bookmarks.sqlite"
    ".local/share/zathura/bookmarks.sqlite-wal"
    ".local/share/zathura/bookmarks.sqlite-shm"
  ];
  programs.zathura = {
    enable = true;
  };
}
