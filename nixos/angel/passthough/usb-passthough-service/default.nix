#https://blog.svenar.nl/posts/vm_usb_passthrough/
{ config, pkgs, ... }: {
  systemd.services."usb-passthough" = {
    serviceConfig = {
      User = "root";
      WorkingDirectory = "/var/lib/usb-passthough";
      ExecStart = (builtins.readDir ./main.py);
    };
  };
  packages = with pkgs; [
    python3Packages.pyudev
  ];

  #users.users.usb-passthough = {
  #  home = "/var/lib/usb-passthouh";
  #  createHome = true;
  #  isSystemUser = true;
  #  group = "virsh";
  #};
  #users.groups.virsh = { };
}
