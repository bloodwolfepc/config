{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "fcitx5";
    syncDirs = [
      ".config/fcitx5"
    ];
    pc-windowrule = [
      "pseudo, fcitx"
    ];
    pc-exec-once = [
      "${pkgs.fcitx5}/bin/fcitx5 -d -r"
      "${pkgs.fcitx5}/bin/fcitx5-remote -r"
    ];
    i18n = {
      inputMethod = {
        enabled = "fcitx5";
        fcitx5 = {
          addons = with pkgs; [
            fcitx5-mozc
            fcitx5-gtk
            fcitx5-hangul
            fcitx5-lua
            fcitx5-table-other
            fcitx5-rose-pine
          ];
        };
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
