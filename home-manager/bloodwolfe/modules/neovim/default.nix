{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "neovim";
    packages = [
      #TODO use forSystem
      inputs.nixvim.packages.x86_64-linux.default 
    ];
    home.sessionVariables = {
      EDITOR = "nvim";
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
