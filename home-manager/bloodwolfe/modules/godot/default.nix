{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "godot";
    packages = with pkgs; [
      #godot_4
    ];
    syncDirs = [
      "godot"
      ".config/godot"
      ".local/share/godot"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
