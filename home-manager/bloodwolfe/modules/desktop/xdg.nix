{
  lib,
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    xdg-utils
    libcanberra-gtk3
    sound-theme-freedesktop
    plasma-overdose-kde-theme
    kdePackages.ocean-sound-theme
  ];
  home.persistence."/sync/home/bloodwolfe".directories = [
    "desktop"
    "documents"
    "music"
    "pictures"
    "videos"
  ];
  xdg = {
    enable = true;
    userDirs =
      let
        me = config.home.homeDirectory;
      in
      {
        enable = true;
        createDirectories = false;
        desktop = "${me}/desktop";
        documents = "${me}/documents";
        download = "${me}/downloads";
        music = "${me}/music";
        pictures = "${me}/pictures";
        videos = "${me}/videos";
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${me}/pictures/screenshots";
          XDG_GAMES_DIR = "${me}/games";
        };
      };
    portal = {
      enable = true;
      xdgOpenUsePortal = false;
    };
  };
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/sound" = {
        theme-name = "Plasma-Overdose";
        event-sounds = true;
        input-feedback-sounds = true;
      };
    };
  };
  qt.enable = true;
  gtk = {
    enable = true;
    gtk2.extraConfig = ''
      gtk-sound-theme-name = "Plasma-Overdose"
    '';
    gtk3.extraConfig = {
      gtk-sound-theme-name = "Plasma-Overdose";
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 1;
      gtk-error-bell = 1;
    };
  };
}
