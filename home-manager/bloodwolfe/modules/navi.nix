{ inputs, ... }:
{
  programs.wolfe-pi = {
    enable = true;
    configPath = inputs.wolfe-pi.outPath;
  };
  # Compatibility for portable consumers until srv migrates its Pi package path.
  home.file.".pi/agent/nix-packages/agents".source = inputs.wolfe-pi.outPath;

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./dotfiles.nix
    ../../../modules/home-manager/backups
    inputs.wolfe-pi.homeManagerModules.packages

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
