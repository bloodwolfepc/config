{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "prismlauncher";
    packages = with pkgs; [
      prismlauncher
      #(prismlauncher.override {
      #  jdks = [ jdk jdk17 jdk8 ];
      #  gamemodeSupport = true;
      #})
      ferium
      packwiz
    ];
    syncDirs = [
      ".local/share/PrismLauncher/instances"
      ".config/ferium"
      ".local/share/packwiz"
    ];
    persistDirs = [
      ".local/share/PrismLauncher/libraries"
      ".local/share/PrismLauncher/assets"
    ];
    persistFiles = [
      ".local/share/PrismLauncher/prismlauncher.cfg"
      ".local/share/PrismLauncher/accounts.json"
      ".local/share/PrismLauncher/metacache"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
