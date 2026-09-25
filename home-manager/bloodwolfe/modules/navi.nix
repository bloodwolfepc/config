{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./dotfiles.nix
    ./pi/packages

    ./account
    ./pi
    ./aichat
    ./attrs-programs
    ./attrs-termial
    ./direnv
    ./kanata
    ./main
    ./neovim
    ./security
    ./virtualisation
    ./yazi
    ./zellij
    ./zsh
  ];
}
