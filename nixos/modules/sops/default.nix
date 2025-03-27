{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "sops";
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      validateSopsFiles = false;
      defaultSopsFormat = "yaml";
      age = {
       sshKeyPaths = [ "/persist/system/etc/ssh/ssh_host_ed25519_key" ];
       keyFile = "/persist/system/var/lib/sops-nix/key.txt";
       generateKey = true; 
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
}
