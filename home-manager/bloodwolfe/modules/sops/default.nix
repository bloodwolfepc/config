{ lib, config, pkgs, inputs, ... }: let 
  secrets = builtins.toString inputs.secrets;
  attrs = lib.custom.mkHomeApplication {
    name = "sops";
    packages = with pkgs; [
      sops
    ];
    sops = {
      age = {
        keyFile = "/persist${config.home.homeDirectory}/.config/sops/age/key.txt";
      }; 
      defaultSopsFile = "${secrets}/secrets/secrets.yaml";
      validateSopsFiles = false; 
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];  
}
