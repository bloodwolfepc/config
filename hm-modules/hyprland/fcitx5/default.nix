{
  pkgs,
  ...
}:
{
  home.persistence."/persist".directories = [
    ".config/fcitx5"
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
