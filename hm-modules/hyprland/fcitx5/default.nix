{
  pkgs,
  ...
}:
{
  home = {
    persistence."/persist".directories = [
      ".config/fcitx5"
    ];
    # packages = with pkgs; [
    #   fcitx5
    #   qt6Packages.fcitx5-configtool
    #   fcitx5-mozc-ut
    #   fcitx5-hangul
    #   fcitx5-gtk
    #   fcitx5-lua
    #   fcitx5-table-other
    #   fcitx5-rose-pine
    # ];
  };

  #https://github.com/inkch/fcitx5-theme-minimal-dark
  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-mozc-ut
          fcitx5-hangul
          fcitx5-gtk
          fcitx5-lua
          fcitx5-table-other
          fcitx5-rose-pine
        ];
        waylandFrontend = true;
        ignoreUserConfig = false;
      };
    };
  };
}
