{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    spotify
    spotify-player
    (pkgs.writeShellScriptBin "src-spotify-player" ''
      ${pkgs.spotify-player}/bin/spotify_player \
      --config-folder $FLAKE/hm-modules/spotify
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
  home.file = {
    ".config/spotify-player/app.toml".source = ./app.toml;
    ".config/spotify-player/keymap.toml".source = ./keymap.toml;
    ".config/spotify-player/theme.toml".source = ./theme.toml;
  };

  systemd.user.services.spotify-player = {
    Unit = {
      Description = "Starts spotify-player daemon";
      After = "network-online.target";
      StartLimitIntervalSec = "600";
      StartLimitBurst = "5";
    };
    Service = {
      Type = "forking";
      ExecStart = lib.escapeShellArgs [
        "${pkgs.spotify-player}/bin/spotify_player"
        "--daemon"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "multi-user.target" ];
    };
  };
}
