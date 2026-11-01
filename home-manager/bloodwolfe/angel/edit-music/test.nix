{ pkgs }:
pkgs.runCommand "edit-music-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  export PYTHONDONTWRITEBYTECODE=1
  python -B ${./.}/test_edit_music.py
  touch "$out"
''
