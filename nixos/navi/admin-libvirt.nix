{ pkgs, ... }:
let
  command = pkgs.writeShellApplication {
    name = "admin-libvirt-command";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.libvirt
    ];
    text = builtins.readFile ./admin-libvirt-command.sh;
  };
in
{
  users.users.bloodwolfe.openssh.authorizedKeys.keys = [
    ''restrict,from="100.64.0.7,192.168.5.4",command="${command}/bin/admin-libvirt-command" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSwwuNMD9yZBpn8d3lNcDhRR3Z84CX5LmsulgFTNhA6 admin-vm-operator-libvirt''
  ];
}
