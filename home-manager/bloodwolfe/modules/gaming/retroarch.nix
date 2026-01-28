{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    rpcs3
    (retroarch.withCores (
      cores: with cores; [
        play
        swanstation
        pcsx-rearmed
        beetle-psx
        snes9x
        pcsx2
        dolphin
        desmume
        bsnes
        nxengine
        dosbox
        easyrpg
      ]
    ))
    retroarch-assets
    retroarch-joypad-autoconfig
  ];
  home.persistence."/persist".directories = [
    "games"
    ".config/retroarch"
    ".config/rpcs3"
    ".cache/rpcs3"
  ];
}
