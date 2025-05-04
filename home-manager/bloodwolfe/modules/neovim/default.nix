{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "neovim";
    packages = [
      (
        if config.enableMinimalNeovim then
          inputs.neovim.packages.${pkgs.system}.minimal
        else
          inputs.neovim.packages.${pkgs.system}.default
      )
      pkgs.nixfmt-rfc-style
    ];
    home.sessionVariables = {
      EDITOR = "nvim";
    };
    inherit config;
    extraOptions = {
      enableMinimalNeovim = lib.mkEnableOption "minimal neovim";
    };
  };
in
{
  inherit (attrs) options config;
}
