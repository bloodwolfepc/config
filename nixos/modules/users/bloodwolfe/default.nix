{
  lib,
  config,
  pkgs,
  ...
}:
{
  sops.secrets.bloodwolfe-pass.neededForUsers = true;
  home-manager.users.bloodwolfe = import ../../../../home-manager/bloodwolfe/${config.networking.hostName};

  users = {
    mutableUsers = false;
    groups = {
      ego = { };
      libvirtd.members = [ "bloodwolfe" ];
      data = {
        name = "data";
      };
    };
    users.ego = {
      isSystemUser = true;
      uid = 155;
      group = "ego";
      createHome = true;
      home = "/home/ego";
      packages = with pkgs; [
        steam
        firefox
      ];
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
        "realtime"
        "ydotool"
        "adbusers"
        "input"
        "uinput"
        "i2c"
        "ego-users"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./id_angel.pub)
      ];
    };
  };
}
