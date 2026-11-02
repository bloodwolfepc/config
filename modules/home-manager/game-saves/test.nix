{ pkgs, home-manager }:
let
  policy = pkgs.writeTextDir "config.yaml" "manifest: {enable: false}\n";
  fixture =
    mutable:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./default.nix
        ../../../home-manager/bloodwolfe/modules/dotfiles.nix
        ({ config, ... }: {
          home = {
            username = "fixture";
            homeDirectory = "/home/fixture";
            stateVersion = "25.11";
          };
          dotfiles = {
            inherit mutable;
            path = "/live/config";
          };
          gameSaves = {
            enable = true;
            configDirectory = "${config.dotfiles.source "game-saves" policy}";
          };
          xdg.configFile."game-saves".source = config.dotfiles.source "game-saves" policy;
        })
      ];
    };
  mutable = fixture true;
  immutable = fixture false;
in
assert pkgs.lib.all (item: item.assertion) immutable.config.assertions;
assert pkgs.lib.all (item: item.assertion) mutable.config.assertions;
assert immutable.config.systemd.user.services.game-saves-backup.Service.UMask == "0077";
pkgs.runCommand "game-saves-tests"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.util-linux
      pkgs.ludusavi
      pkgs.jq
      pkgs.shellcheck
      pkgs.python3
      pkgs.ruff
    ];
    RUNNER = ./game-saves.sh;
    GAME_SAVES_RECEIVER = "${./receive.py}";
    GAME_SAVES_NATIVE = pkgs.lib.getExe pkgs.ludusavi;
    LUDUSAVI_TEST_BIN = pkgs.lib.getExe pkgs.ludusavi;
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    export RUFF_CACHE_DIR="$TMPDIR/ruff"
    shellcheck ${./game-saves.sh} ${./test.sh}
    ruff check --select E9,F ${./receive.py} ${./test_receive.py}
    python3 -B ${./.}/test_receive.py
    bash ${./test.sh}
    ${immutable.config.gameSaves.package}/bin/game-saves --help > help.txt
    grep -q 'Back up and restore' help.txt
    test "$(readlink ${mutable.config.xdg.configFile."game-saves".source})" = /live/config/game-saves
    touch "$out"
  ''
