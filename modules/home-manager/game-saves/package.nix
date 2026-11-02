{
  pkgs,
  configDirectory,
  stateDirectory,
  backupDirectory,
  inboxDirectory,
  statusDirectory,
  refreshCommand,
}:
pkgs.writeShellApplication {
  name = "game-saves";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.util-linux
    pkgs.ludusavi
    pkgs.python3
  ];
  runtimeEnv = {
    GAME_SAVES_CONFIG = configDirectory;
    GAME_SAVES_STATE = stateDirectory;
    GAME_SAVES_BACKUPS = backupDirectory;
    GAME_SAVES_INBOX = inboxDirectory;
    GAME_SAVES_STATUS = statusDirectory;
    GAME_SAVES_RECEIVER = "${./receive.py}";
    GAME_SAVES_NATIVE = pkgs.lib.getExe pkgs.ludusavi;
    GAME_SAVES_REFRESH = if refreshCommand == null then "" else refreshCommand;
  };
  text = builtins.readFile ./game-saves.sh;
}
