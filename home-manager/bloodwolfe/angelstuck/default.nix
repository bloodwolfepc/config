{ lib, ... }:
{
  imports = [ ../angel ];

  dotfiles.mutable = lib.mkForce false;
}
