{
  pkgs,
  lib,
  ...
}:
{
  home.persistence = {
    "/persist".directories = [
      "programfiles"
      "src"
      "library"
      "qemu"

      ".mozilla"
      ".cache/mozilla"
      ".config/mozilla"
      ".cache/flatpak"
      ".config/kdeconnect"
      ".config/spotify"
      ".config/vesktop"
      ".config/legcord"

      ".local/share/flatpak"
      ".local/state/wireplumber"

      ".local/share/zathura"
    ];
  };
  home.packages = with pkgs; [
    #spotify
    vesktop
    legcord

    #wineWowPackages.stagingFull
    winetricks

    xournalpp
  ];
  programs.firefox.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };

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

  programs.zathura = {
    enable = true;
  };
}
