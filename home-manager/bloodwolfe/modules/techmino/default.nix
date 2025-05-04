{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "techmino";
    packages = with pkgs; [
      techmino
    ];
    syncDirs = [
      "./local/share/love/Techmino"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
