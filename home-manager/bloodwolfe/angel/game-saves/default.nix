{ config, ... }:
let
  nativeConfig = config.dotfiles.source "game-saves" ../../modules/game-saves;
in
{
  imports = [ ../../../../modules/home-manager/game-saves ];
  gameSaves = {
    enable = true;
    configDirectory = "${nativeConfig}";
    stateDirectory = "/persist${config.xdg.stateHome}/game-saves";
  };
  xdg.configFile."game-saves".source = nativeConfig;
  home.persistence."/persist".directories = [ ".local/state/game-saves" ];
  home.backups.state.paths = [ ".local/share/nextcloud-sync/game-saves" ];
}
