{ lib, config }:
{
  custom = import ./custom.nix { inherit lib config; };
}
