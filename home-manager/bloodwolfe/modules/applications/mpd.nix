{
  config,
  pkgs,
  ...
}:
{
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/music";
    extraConfig = ''
      connection_timeout "5"
    '';
  };
  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-spotify
      mopidy-mpd
      mopidy-mpris
    ];
    settings = {
      file = {
        media_dirs = [
          "${config.home.homeDirectory}/music"
        ];
        follow_symlinks = true;
        excluded_file_extensions = [
          ".html"
          ".zip"
          ".jpg"
          ".jpeg"
          ".png"
        ];
      };
    };
  };
  programs.ncmpcpp = {
    enable = true;
    bindings = [
      {
        key = "j";
        command = "scroll_down";
      }
      {
        key = "k";
        command = "scroll_up";
      }
      {
        key = "J";
        command = [
          "select_item"
          "scroll_down"
        ];
      }
      {
        key = "K";
        command = [
          "select_item"
          "scroll_up"
        ];
      }
    ];
  };
  programs.cmus = {
    enable = true;
    extraConfig = ''
      set audio_backend = "mpd"
      set status_display = "deafult"
    '';
  };
  programs.beets = {
    enable = true;
    mpdIntegration = {
      enableStats = true;
      enableUpdate = true;
    };
  };
}
