/*
  --NOTICE--
  There is an issue with bwrap and impermanence
  where steam is not be able to find and write some stuff
  even with elevated permissions
  this is exclusive to the impermanence module bindmounts
  and is temporaraly resolved with a btrfs
  subvolume called flatpak that is mounted to .var/app
*/

{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "flatpak";
    persistDirs = [
      ".cache/flatpak"
      ".local/share/flatpak"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
