{ pkgs, ... }:
{
  imports = [
    ../modules/account.nix
    ../modules/system
    ../modules/security
    ../modules/applications
    ../modules/terminal
    ../modules/desktop

    ../modules/terminal/zsh.nix
    ../modules/terminal/yazi
    ../modules/terminal/subtui.nix
    ../modules/terminal/zellij
  ];

  home.packages = with pkgs; [
    vim
  ];
}
