{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "xournalpp";
    packages = with pkgs; [
      zathura
    ];
    syncDirs = [
      ".config/xournalpp"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
