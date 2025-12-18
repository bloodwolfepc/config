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
  ];
  home.packages = with pkgs; [
    unscii
  ];
  fonts.fontconfig.enable = true;
}
