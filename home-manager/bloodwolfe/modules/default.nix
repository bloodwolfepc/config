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
    ./direnv.nix
  ];
}
