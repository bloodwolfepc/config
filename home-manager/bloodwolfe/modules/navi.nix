{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./dotfiles.nix
    ./pi/packages

    ./attrs-programs
    ./attrs-termial
    ./direnv
    ./kanata
    ./main
    ./security
    ./virtualisation
    ./yazi
    ./zellij
    ./zsh
  ];
}
