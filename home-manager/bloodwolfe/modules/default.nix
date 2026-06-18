{ pkgs, config, ... }:
{
  home.sessionVariables."FLAKE" = "${config.home.homeDirectory}/src/config";
  imports = [
    ./account.nix
    ./gaming
    ./system
    ./security
    ./workstation
    ./applications
    ./terminal
    ./kanata
    ./aichat
    ./direnv.nix
    ./hyprland
  ];
}
