{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./dotfiles.nix
    ../../../modules/home-manager/backups
    ./pi/packages

    ./attrs-programs
    ./attrs-termial
    ./direnv
    ./main
    ./security
    ./virtualisation
    ./yazi
    ./zellij
    ./zsh
  ];
}
