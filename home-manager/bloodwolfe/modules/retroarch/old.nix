{ }
#{ pkgs, ... }: {
#  home.packages = with pkgs; [
#    retroarchFull
#    #(retroarchFull.override {
#    #  cores = with libretro; [
#    #    play
#    #    swanstation
#    #    pcsx-rearmed
#    #    beetle-psx
#    #    snes9x
#    #    pcsx2
#    #    dolphin
#    #    desmume
#    #    bsnes
#    #    nxengine #cave story
#    #    dosbox
#    #  ];
#    #})
#    retroarch-assets
#    retroarch-joypad-autoconfig
#  ];
#  home.persistence."/sync/home/bloodwolfe" = {
#    directories = [
#      "games"
#      ".config/retroarch/saves"
#      ".config/retroarch/states"
#      ".config/retroarch/system"
#      ".config/retroarch/config"
#    ];
#    files = [
#      ".config/retroarch/retroarch.cfg"
#    ];
#  };
#	home.persistence."/persist/home/bloodwolfe" = {
#		directories = [
#      ".config/retroarch/database"
#      ".config/retroarch/thumbnails"
#    ];
#  };
#}
