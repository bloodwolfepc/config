{ pkgs, ... }:
{
  imports = [
    ./account.nix
    ./gaming
    ./desktop
    ./system
    ./security
    ./workstation
    ./applications
    ./terminal
    ./kanata
    ./aichat
    ./direnv.nix
  ];
}
