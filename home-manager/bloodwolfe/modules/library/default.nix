{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "library";
    syncDirs = [
      "library"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
