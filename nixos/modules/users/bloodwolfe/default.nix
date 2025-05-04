{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkConfig {
    name = "bloodwolfe";
    sops.secrets.bloodwolfe-pass.neededForUsers = true;
    home-manager.users.bloodwolfe = import ../../../../home-manager/bloodwolfe/${config.networking.hostName};

    users = {
      mutableUsers = false;
      groups = {
        libvirtd.members = [ "bloodwolfe" ];
        data = {
          name = "data";
        };
      };
      users.bloodwolfe = {
        isNormalUser = true;
        hashedPasswordFile = lib.mkDefault config.sops.secrets.bloodwolfe-pass.path;
        shell = pkgs.zsh;
        extraGroups = [
          "syncthing"
          "wheel"
          "audio"
          "video"
          "networkmanager"
          "libvirtd"
          "qemu-libvirtd"
          "disk"
          "docker"
          "keys"
          "data"
          "libvirtd"
          "realtime"
          "ydotool"
          "adbusers"
        ];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ./keys/id_angel.pub)
        ];
      };
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
