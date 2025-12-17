{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./mpd.nix
    ./alacritty.nix
  ];
  wayland.windowManager.hyprland.settings.windowrulev2 = [
    "workspace 2 silent, initialClass:^([Ss]potify)$"
    "workspace 3 silent, initialClass:^([Vv]esktop)$"
    "workspace 3 silent, initialClass:^([Vv]esktop)$, initialTitle:^([Vv]esktop)$"
  ];
  home.persistence = {
    "/sync/home/bloodwolfe".directories = [
      "appimages"
      "library"
      "notebook"
      "qemu"
      "wine"

      ".local/share/zathura"
    ];
    "/persist/home/bloodwolfe".directories = [
      "src"

      ".mozilla"
      ".cache/mozilla"
      ".cache/flatpak"
      ".config/kdeconnect"
      ".config/spotify"
      ".config/vesktop"

      ".local/share/flatpak"
      ".local/state/wireplumber"
    ];
  };
  home.packages = with pkgs; [
    spotify
    vesktop

    wineWowPackages.stagingFull
    winetricks

    zathura
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

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
