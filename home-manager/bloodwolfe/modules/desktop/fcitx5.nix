{
  pkgs,
  ...
}:
{
  home.persistence."/persist/home/bloodwolfe".directories = [
    ".config/fcitx5"
  ];
  wayland.windowManager.hyprland.settings.exec-once = [
    "${pkgs.fcitx5}/bin/fcitx5 -d -r"
    "${pkgs.fcitx5}/bin/fcitx5-remote -r"
  ];
  i18n = {
    inputMethod = {
      type = "fcitx5";
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
}
