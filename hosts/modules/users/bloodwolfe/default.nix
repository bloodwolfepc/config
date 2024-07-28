{ pkgs, config, ... }:
{
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
      "wheel"
      "audio"
      "video"
      "networkmanager"
      "libvirtd"
      "docker"
      "keys"
      "data"
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./keys/ssh-lapis.pub)
      (builtins.readFile ./keys/ssh-angel.pub)
    ];
  };

  home-manager.users.bloodwolfe = import ../../../../home/bloodwolfe/${config.networking.hostName}.nix;
}

