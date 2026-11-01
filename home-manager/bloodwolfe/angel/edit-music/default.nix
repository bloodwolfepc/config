{ pkgs }:
pkgs.writeShellApplication {
  name = "edit-music";
  runtimeInputs = [ pkgs.openssh ];
  text = ''
    set +x
    exec ${pkgs.python3}/bin/python3 ${./edit_music.py} "$@"
  '';
}
