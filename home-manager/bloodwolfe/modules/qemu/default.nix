{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "qemu";
    inherit config;
    syncDirs = [
      "qemu"
    ];
  };
in
{
  inherit (attrs) options config;
}
