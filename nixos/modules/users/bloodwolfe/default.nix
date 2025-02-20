{ pkgs, config, ... }: {
  users.groups.libvirtd.members = ["bloodwolfe"];
  sops.secrets.bloodwolfe-pass.neededForUsers = true;
  users.mutableUsers = false;
  users.groups.data = {
    name = "data";
  };

  users.users.bloodwolfe = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.bloodwolfe-pass.path;
    #useDefaultShell = true;
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
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./keys/id_angel.pub)
    ];
  };

  home-manager.users.bloodwolfe = import ../../../../home-manager/bloodwolfe/${config.networking.hostName};
}

