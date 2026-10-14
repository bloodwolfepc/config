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
  home.persistence."/persist".directories = [
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
        setSessionVariables = true;
        desktop = "${me}/desktop";
        documents = "${me}/documents";
        download = "${me}/downloads";
        music = "${me}/music";
        pictures = "${me}/pictures";
        videos = "${me}/videos";
        extraConfig = {
          SCREENSHOTS = "${me}/pictures/screenshots";
          GAMES = "${me}/games";
        };
      };
    portal = {
      enable = true;
      #xdgOpenUsePortal = false;
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
  home.sessionVariables = {
    D = "~/downloads";
  };
}
