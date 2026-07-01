{
  config,
  pkgs,
  ...
}:
let
  extraPkgs =
    pkgs: with pkgs; [
      gamescope
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
    ];

  # steam-with-pkgs = pkgs.millennium-steam.override {
  #   inherit extraPkgs;
  #   extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${pkgs.dwproton-bin.steamcompattool}'";
  # };
  millennium-with-pkgs = pkgs.millennium-steam.override {
    inherit extraPkgs;
    extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${pkgs.dwproton-bin.steamcompattool}'";
  };
in
{
  home.packages =
    with pkgs;
    [
      gamescope
      steamcmd
      steam-run
      protonup-ng
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
