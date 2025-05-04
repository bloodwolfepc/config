{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "obs";
    packages = with pkgs; [
      obs-studio
      obs-cli
      obs-studio-plugins.obs-3d-effect
      obs-studio-plugins.input-overlay
      obs-studio-plugins.obs-tuna
    ];
    syncDirs = [
      ".config/obs-studio"
      "obs"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
