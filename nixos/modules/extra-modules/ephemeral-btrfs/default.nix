{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "ephemeral-btrfs";
    boot.initrd.postDeviceCommands = lib.mkAfter 
      (builtins.readFile ./ephemeral-btrfs.sh);
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
