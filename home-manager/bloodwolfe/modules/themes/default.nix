{ config, ... }:
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile = {
    "gtk-3.0/gtk.css".source = config.dotfiles.source "themes/wolfe/gtk/gtk.css" ./wolfe/gtk/gtk.css;
    "gtk-3.0/settings.ini".source =
      config.dotfiles.source "themes/wolfe/gtk/settings.ini" ./wolfe/gtk/settings.ini;
    "gtk-4.0/gtk.css".source = config.dotfiles.source "themes/wolfe/gtk/gtk.css" ./wolfe/gtk/gtk.css;
    "gtk-4.0/settings.ini".source =
      config.dotfiles.source "themes/wolfe/gtk/settings.ini" ./wolfe/gtk/settings.ini;
    "Kvantum/kvantum.kvconfig".source =
      config.dotfiles.source "themes/wolfe/kvantum/kvantum.kvconfig" ./wolfe/kvantum/kvantum.kvconfig;
    "Kvantum/wolfe".source = config.dotfiles.source "themes/wolfe/kvantum/wolfe" ./wolfe/kvantum/wolfe;
    "qt5ct/qt5ct.conf".source = config.dotfiles.source "themes/wolfe/qt5ct.conf" ./wolfe/qt5ct.conf;
  };
}
