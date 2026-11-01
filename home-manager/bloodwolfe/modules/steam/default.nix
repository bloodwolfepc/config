{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  extraPkgs =
    pkgs: with pkgs; [
      libXcursor
      libXi
      libXinerama
      libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      libkrb5
      keyutils
    ];
  extraCompatPackages = with pkgs; [
    dwproton-bin
    proton-ge-bin
  ];
  extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" extraCompatPackages;
  terrariaSteamSaves =
    lib.concatMap
      (
        root:
        lib.concatMap
          (id: [
            "${root}/userdata/*/${id}/remote"
            "${root}/steamapps/compatdata/${id}/pfx/drive_c/users/steamuser/Documents/My Games/Terraria"
          ])
          [
            "105600"
            "1281930"
          ]
      )
      [
        ".local/share/Steam"
        ".local/share/steamgames"
      ];

  # steam-with-pkgs = pkgs.steam.override {
  #   inherit extraPkgs;
  #   extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${pkgs.dwproton-bin.steamcompattool}'";
  # };
  # Keep the dependency hash and native libraries on upstream's matching Steam runtime.
  millennium-with-pkgs =
    inputs.millennium.packages.${pkgs.stdenv.hostPlatform.system}.millennium-steam.override
      {
        inherit extraPkgs;
        extraEnv = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = extraCompatPaths;
        };
        # extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${pkgs.dwproton-bin.steamcompattool}'";
      };
in
{
  home.packages =
    with pkgs;
    [
      gamescope
      (pkgs.writeShellScriptBin "gamescope-dynamic" ''
        set -euo pipefail

        monitor_info="$(
          hyprctl monitors -j | jq -r '
            (map(select(.focused == true)) | .[0] // .[0]) as $m
            | "\($m.width) \($m.height) \($m.refreshRate | round)"
          '
        )"

        read -r width height refresh <<< "$monitor_info"
        exec ${pkgs.gamescope}/bin/gamescope -W "$width" -H "$height" -r "$refresh" -- "$@"
      '')
      steamcmd
      steam-run
      protontricks
      winetricks
      steam-rom-manager
      steamguard-cli
      depotdownloader
      samrewritten
      umu-launcher-unwrapped
      vkbasalt
      vkbasalt-cli
    ]
    ++ [
      millennium-with-pkgs
    ];
  home.persistence."/persist".directories = [
    ".local/share/Steam"
    ".local/share/steamgames"
    ".local/share/millennium"
    ".config/millennium"
    ".local/share/Terraria"
  ];
  home.backups.terraria.paths = [ ".local/share/Terraria" ] ++ terrariaSteamSaves;
  home.backups.state = {
    paths = [
      ".config/millennium/quick.css"
      # The backend reads this only for sanitizing; never upload the raw file.
      ".config/millennium/config.json"
    ];
    exclude = [ "**/.config/millennium/config.json" ];
    backupPrepareCommand = ''
      file="$BACKUP_ROOT/.config/millennium/config.json"
      if [[ -f "$file" && ! -L "$file" ]]; then
        ${lib.getExe pkgs.jq} 'with_entries(select(.key == "general" or .key == "themes" or .key == "notifications" or .key == "plugins" or .key == "misc"))' "$file" > "$RUNTIME_DIRECTORY/millennium.json"
      else
        printf '{}\n' > "$RUNTIME_DIRECTORY/millennium.json"
      fi
    '';
    dynamicFilesFrom = ''printf '%s\n' "$RUNTIME_DIRECTORY/millennium.json"'';
  };
  sops.secrets = {
    "steamguard-manifest-json" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/manifest.json";
    };
    "steamguard-user-mafile" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/1.maFile";
    };
  };
}
