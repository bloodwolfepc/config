{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "mpd";
    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/music";
      extraConfig = ''
        connection_timeout "5"
      '';
    };
    services.mpd-mpris = {
      enable = true;
    };
    services.mpdris2 = {
      enable = true;
    };
    services.mpd-discord-rpc = { };
    services.listenbrainz-mpd = { }; #scrobbler
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
        #spotify = {
        #  client_id = "CLIENT_ID";
        #  client_secret = "CLIENT_SECRET";
        #};
      };
    };
    programs.ncmpcpp = {
      enable = true;
      bindings = [
        { key = "j"; command = "scroll_down"; }
        { key = "k"; command = "scroll_up"; }
        { key = "J"; command = [ "select_item" "scroll_down" ]; }
        { key = "K"; command = [ "select_item" "scroll_up" ]; }
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
    inherit config;
  };
in {
  inherit (attrs) options config;
}
