{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "bevy";
    syncDirs = [
      "bevy"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
