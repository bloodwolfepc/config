{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "neovim";
    packages = [
      inputs.neovim.packages.${pkgs.system}.default 
    ];
    home.sessionVariables = {
      EDITOR = "nvim";
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
