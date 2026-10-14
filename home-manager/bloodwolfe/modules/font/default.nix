{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    unscii
    ark-pixel-font
    migu
    nerd-fonts.symbols-only
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.emoji = [ ];
  };

  xdg.configFile."fontconfig/conf.d/90-unscii-aliases.conf".source =
    config.dotfiles.source "font/90-unscii-aliases.conf" ./90-unscii-aliases.conf;
}
