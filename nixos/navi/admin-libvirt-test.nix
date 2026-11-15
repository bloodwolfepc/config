{ pkgs, ... }:
pkgs.runCommand "admin-libvirt-command-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.python3
      pkgs.shellcheck
    ];
  }
  ''
    bash -n ${./admin-libvirt-command.sh}
    shellcheck ${./admin-libvirt-command.sh}
    python3 -B ${./admin-libvirt-test.py} ${./admin-libvirt-command.sh}
    touch "$out"
  ''
