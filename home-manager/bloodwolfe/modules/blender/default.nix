{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "blender";
    packages = with pkgs; [
      blender
    ];
    syncDirs = [
      "blender"
      ".config/blender"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
