{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "neovim";
    packages = [
      #TODO use forSystem
      inputs.nixvim.packages.x86_64-linux.default 
    ];
    inherit config;
    inherit extraHomeConfig;
  }; 
  extraHomeConfig = {
    sessionVariables = {
      EDITOR = "nvim";
    };
  };
in {
  inherit (attrs) options config;
}