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
  home.persistence."/persist/home/bloodwolfe".directories = [
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
      steam-gamescope-session
    ];
  sops.secrets = {
    "steamguard-manifest-json" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/manifest.json";
    };
    "steamguard-user-mafile" = {
      path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/1.maFile";
    };
  };

  wayland.windowManager.hyprland.settings.windowrulev2 =
    let
      adhere-workspace = "6";
      games-workspace = "5";
    in
    [
      "tile, class:^([Ss]team)$, title:^([Ss]team)$"
      "bordercolor rgb(000000), class:^([Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, initialTitle:^([Ff]riends [Ll]ist)$"
      "workspace ${adhere-workspace}, initialTitle:^([Ss]team)$" # updating steam... window, class is "" and title is Steam
      "workspace 11 silent, class:^([Ss]team)$, title:^([Ss]pecial [Oo]fers)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]team [Ss]ettings)$"
      "float, class:^([Ss]team)$, title:^([Ss]team [Ss]ettings)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]ign [Ii]n [Tt]o [Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^(notificationtoasts)"
      "bordercolor rgb(000000), class:^steam_app_[0-9]+$"
      "bordercolor rgb(000000), class:^([Ss]team)$"

      "workspace ${games-workspace} silent, class:^steam_app_[0-9]+$"
      "workspace ${games-workspace} silent, initialClass:^([Cc]s2)$"
      "workspace ${games-workspace} silent, initialClass:tf_linux64"
      "renderunfocused, class:^steam_app_[0-9]+$"
      "renderunfocused, initialClass:^([Cc]s2)$"
      "renderunfocused, initialClass:tf_linux64"
      "immediate, class:^steam_app_[0-9]+$"
      "immediate, initialClass:^(cs2)$"
      "immediate, initialClass:^(tf_linux64)$"
    ];
}
