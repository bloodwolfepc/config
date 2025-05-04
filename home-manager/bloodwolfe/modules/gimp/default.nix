{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "gimp";
    packages = with pkgs; [
      gimp
    ];
    syncDirs = [
      "gimp"
      ".config/GIMP"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
