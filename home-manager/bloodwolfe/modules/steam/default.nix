{ lib, config, pkgs, ... }: let
  attrs = let 
    steam-with-pkgs = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          curl
          renderdoc
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
  in lib.custom.mkHomeApplication {
    name = "steam";
    persistDirs = [
      ".local/share/Steam"
    ];
    packages = with pkgs; [
      steamcmd
      steam-run
      protonup-ng
      protontricks
      steamguard-cli
      steam-rom-manager
      depotdownloader
      samrewritten
      umu-launcher-unwrapped
      steam-tui
      vkbasalt
      vkbasalt-cli
    ] ++ [ steam-with-pkgs ];
    #++ with pkgs.tf2Huds [ minthud ];
    pcWindowRule = let 
      adhere-workspace = "6";
      games-workspace = "5";
    in [
      #maybe auto resize friends list, determine notificationtoast size for workspace allocation using ipc,
      "float, class:^([Ss]team)$, title:^((?![Ss]team).*)$"
      "tile, class:^([Ss]team)$, title:^([Ss]team)$"
      "bordercolor rgb(000000), class:^([Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, initialTitle:^([Ff]riends [Ll]ist)$"
      "workspace ${adhere-workspace}, initialTitle:^([Ss]team)$" #updating steam... window, class is "" and title is Steam
      "workspace 11 silent, class:^([Ss]team)$, title:^([Ss]pecial [Oo]fers)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]team [Ss]ettings)$"
      "float, class:^([Ss]team)$, title:^([Ss]team [Ss]ettings)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]ign [Ii]n [Tt]o [Ss]team)$"
      "workspace ${adhere-workspace} silent, class:^([Ss]team)$, title:^(notificationtoasts)"
      "workspace ${games-workspace} silent, class:^steam_app_[0-9]+$"
      "bordercolor rgb(000000), class:^steam_app_[0-9]+$"
      "bordercolor rgb(000000), class:^([Ss]team)$"

      "workspace ${games-workspace} silent, initialClass:^([Cc]s2)$"
    ];
    sops.secrets = {
      "steamguard-manifest-json" = {
        path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/manifest.json";
      };
      "steamguard-user-mafile" = {
        path = "${config.home.homeDirectory}/.config/steamguard-cli/maFiles/1.maFile";
      };
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
