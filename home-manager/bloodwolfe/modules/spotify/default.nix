{
  config,
  pkgs,
  lib,
  ...
}:
let
  playerConfig = config.dotfiles.source "spotify/config" ./config;
in
{
  home.packages = with pkgs; [
    spotify
    spotify-player
    spotifyd
    (pkgs.writeShellScriptBin "src-spotify-player" ''
      ${pkgs.spotify-player}/bin/spotify_player \
      --config-folder ${playerConfig} \
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

  home.file = {
    ".config/spotify-player/app.toml".source =
      config.dotfiles.source "spotify/config/app.toml" ./config/app.toml;
    ".config/spotify-player/keymap.toml".source =
      config.dotfiles.source "spotify/config/keymap.toml" ./config/keymap.toml;
    ".config/spotify-player/theme.toml".source =
      config.dotfiles.source "spotify/config/theme.toml" ./config/theme.toml;
    ".config/spotifyd/spotifyd.conf".source =
      config.dotfiles.source "spotify/spotifyd-config/spotifyd.conf" ./spotifyd-config/spotifyd.conf;
  };
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
}
