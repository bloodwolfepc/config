{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    spotify
    spotify-player
    # spotifyd
    (pkgs.writeShellScriptBin "src-spotify-player" ''
      ${pkgs.spotify-player}/bin/spotify_player \
      --config-folder $FLAKE/hm-modules/spotify/config \
      "$@"
    '')
  ];

  home.persistence = {
    "/persist".directories = [
      ".config/spotify"
      ".cache/spotify"
      ".config/spotify-player"
      ".cache/spotify-player"
    ];
  };

  home.file.".config/spotify-player" = {
    source = ./config;
    recursive = true;
  };
  home.file.".config/spotify-player-daemon" = {
    source = ./daemon-config;
    recursive = true;
  };

  systemd.user.services.spotify-player = {
    Unit = {
      Description = "Starts spotify-player daemon";
      StartLimitIntervalSec = "600";
      StartLimitBurst = "5";
    };
    Service = {
      Type = "forking";
      ExecStart = lib.escapeShellArgs [
        "${pkgs.spotify-player}/bin/spotify_player"
        "--config-folder"
        "${config.xdg.configHome}/spotify-player-daemon"
        "--daemon"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
