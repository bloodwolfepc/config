{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "pixelorama";
    packages = with pkgs; [
      #pixelorama
    ];
    syncDirs = [
      ".local/share/pixelorama"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
