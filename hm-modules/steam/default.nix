{
  config,
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

  # steam-with-pkgs = pkgs.steam.override {
  #   inherit extraPkgs;
  #   extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${pkgs.dwproton-bin.steamcompattool}'";
  # };
  millennium-with-pkgs = pkgs.millennium-steam.override {
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
  ];
  sops.secrets = {
    "steamguard-manifest-json" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/manifest.json";
    };
    "steamguard-user-mafile" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/1.maFile";
    };
  };
}
