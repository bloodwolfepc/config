{
  config,
  pkgs,
  lib,
  ...
}:
let
  playerConfig = config.dotfiles.source "spotify/config" ./config;
  daemonConfig = config.dotfiles.source "spotify/spotifyd-config" ./spotifyd-config;
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

  home.file.".config/spotify-player" = {
    source = playerConfig;
    recursive = true;
  };
  home.file.".config/spotifyd" = {
    source = daemonConfig;
    recursive = true;
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
