{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "freecad";
    packages = with pkgs; [
      freecad
    ];
    syncDirs = [
      "cadfiles"
      ".config/freecad"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
