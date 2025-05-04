{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "kdenlive";
    packages = with pkgs; [
      libsForQt5.kdenlive
    ];
    syncDirs = [
      ".local/share/kdenlive"
    ];
    syncFiles = [
      ".config/kdenliverc"
      ".config/kdenlive-layoutrc"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
