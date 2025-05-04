{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "olive-editor";
    packages = with pkgs; [
      olive-editor
    ];
    syncDirs = [
      "olive"
      #TODO config sync dirs
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
