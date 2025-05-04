{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "krita";
    packages = with pkgs; [
      krita
    ];
    syncDirs = [
      "krita"
      ".local/share/krita"
    ];
    syncFiles = [
      ".config/kritarc"
      ".config/kritadisplayrc"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
