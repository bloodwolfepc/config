{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "sops";
    packages = with pkgs; [
      sops
    ];
    inherit config;
    inherit extraConfig;
  }; 
  extraConfig = {
    sops = {
      age = {
        keyFile = "/persist${config.home.homeDirectory}/.config/sops/age/key.txt";
      }; 
      defaultSopsFile = ../../../../secrets/secrets.yaml;
      validateSopsFiles = false; 
    };
  };
in {
  inherit (attrs) options config;
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];  
}
