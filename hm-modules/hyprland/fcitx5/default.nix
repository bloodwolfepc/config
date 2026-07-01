{
  pkgs,
  ...
}:
{
  home = {
    persistence."/persist".directories = [
      ".config/fcitx5"
    ];
    packages = with pkgs; [
      fcitx5
      qt6Packages.fcitx5-configtool
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-hangul
      fcitx5-lua
      fcitx5-table-other
      fcitx5-rose-pine
    ];
  };
  #https://github.com/inkch/fcitx5-theme-minimal-dark
  # i18n = {
  #   inputMethod = {
  #     type = "fcitx5";
  #     fcitx5 = {
  #       addons = with pkgs; [
  #         fcitx5-mozc
  #         fcitx5-gtk
  #         fcitx5-hangul
  #         fcitx5-lua
  #         fcitx5-table-other
  #         fcitx5-rose-pine
  #       ];
  #       waylandFrontend = true;
  #       ignoreUserConfig = true;
  #       settings.inputMethod = {
  #         GroupOrder."0" = "Default";
  #         "Groups/0" = {
  #           Name = "Default";
  #           "Default Layout" = "jp";
  #           DefaultIM = "mozc";
  #         };
  #         "Groups/0/Items/0".Name = "keyboard-jp";
  #         "Groups/0/Items/1".Name = "mozc";
  #       };
  #     };
  #   };
  # };
}
