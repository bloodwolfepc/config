{
  pkgs,
  lib,
  lockFile,
  guard ? "",
}:
pkgs.writeShellScriptBin "restic" ''
  umask 077
  exec ${pkgs.util-linux}/bin/flock --timeout 21600 ${lib.escapeShellArg lockFile} ${pkgs.writeShellScript "restic-under-lock" ''
    set -Eeuo pipefail
    ${guard}
    exec ${lib.getExe pkgs.restic} "$@"
  ''} "$@"
''
