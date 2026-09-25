{ config, ... }: {
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };
  home.file.".config/MangoHud/MangoHud.conf".source =
    config.dotfiles.source "mangohud/MangoHud.conf" ./MangoHud.conf;
}
