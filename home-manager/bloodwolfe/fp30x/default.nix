{ pkgs, ... }:
{
  imports = [
    ../modules/account.nix
    ../modules/system
    ../modules/security
    ../modules/applications
    ../modules/terminal

    ../modules/desktop
    ../modules/applications
  ];
}
