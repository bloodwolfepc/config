{
  lib,
  config,
  pkgs,
  outputs,
  ...
}:
let
  steam-with-pkgs = pkgs.steam.override {
    extraPkgs =
      pkgs: with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        gamescope
      ];
  };
in
{
  home.persistence."/persist".directories = [
    ".local/share/Steam"
    ".local/share/steamgames"
  ];
  home.packages =
    with pkgs;
    [
      steamcmd
      steam-run
      protonup-ng
      protontricks
      winetricks
      steamguard-cli
      steam-rom-manager
      depotdownloader
      samrewritten
      umu-launcher-unwrapped
      vkbasalt
      vkbasalt-cli
    ]
    ++ [
      steam-with-pkgs
    ];
  sops.secrets = {
    "steamguard-manifest-json" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/manifest.json";
    };
    "steamguard-user-mafile" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/1.maFile";
    };
  };
  wayland.windowManager.hyprland.settings.windowrule =
    let
      steam-workspace = "6";
      games-workspace = "5";
    in
    [
      "match:class ^([Ss]team)$, workspace ${steam-workspace} silent"
      "match:class ^([Ss]team)$, border_color rgb(000000)"
      "match:initial_title ^([Ff]riends [Ll]ist)$, border_color rgb(ff00ff)"

      "match:class ^steam_app_[0-9]+$, workspace ${games-workspace} silent"
      "match:class tf_linux64, workspace ${games-workspace} silent"
      "match:class ^([Cc]s2)$, workspace ${games-workspace} silent"
    ];
}
