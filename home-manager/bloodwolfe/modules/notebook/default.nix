{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "notebook";
    syncDirs = [
      "notebook"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
