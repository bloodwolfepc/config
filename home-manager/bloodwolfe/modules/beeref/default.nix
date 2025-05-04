{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "beeref";
    syncDirs = [
      "beeref"
      ".config/BeeRef"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
