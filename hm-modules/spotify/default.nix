{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    spotify
    spotify-player
    spotifyd
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
      ".config/spotifyd"
      ".cache/spotifyd"
    ];
  };

  home.file.".config/spotify-player" = {
    source = ./config;
    recursive = true;
  };
  home.file.".config/spotifyd" = {
    source = ./spotifyd-config;
    recursive = true;
  };
  # home.file.".config/spotify-player-daemon" = {
  #   source = ./daemon-config;
  #   recursive = true;
  # };

  systemd.user.services.spotifyd = {
    Unit = {
      Description = "A spotify playing daemon";
      Documentation = "https://github.com/Spotifyd/spotifyd";
    };
    Service = {
      ExecStart = lib.escapeShellArgs [
        "${pkgs.spotifyd}/bin/spotifyd"
        "--no-daemon"
      ];
      Restart = "always";
      RestartSec = 12;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # systemd.user.services.spotify-player = {
  #   Unit = {
  #     Description = "Starts spotify-player daemon";
  #     StartLimitIntervalSec = "600";
  #     StartLimitBurst = "5";
  #   };
  #   Service = {
  #     Type = "forking";
  #     ExecStart = lib.escapeShellArgs [
  #       "${pkgs.spotify-player}/bin/spotify_player"
  #       "--config-folder"
  #       "${config.xdg.configHome}/spotify-player-daemon"
  #       "--daemon"
  #     ];
  #     Restart = "always";
  #     RestartSec = 5;
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };
}
