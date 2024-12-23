{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "xdg";
    syncDirs = [
      "desktop"
      "documents"
      "music"
      "pictures"
      "videos"
      "snips"
    ];
    xdg.userDirs = let 
      me = config.home.homeDirectory;
    in {
      enable = true;
      createDirectories = false;
      desktop = "${me}/desktop";
      documents = "${me}/documents";
      download = "${me}/downloads";
      music = "${me}/music";
      pictures = "${me}/pictures";
      videos = "${me}/videos";
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${me}/snips";
      };
    }; 
    inherit config;
  };
in {
  inherit (attrs) options config;
}
