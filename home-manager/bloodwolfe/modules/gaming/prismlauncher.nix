{
  lib,
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    prismlauncher
    #(prismlauncher.override {
    #  jdks = [ jdk jdk17 jdk8 ];
    #  gamemodeSupport = true;
    #})
    ferium
    packwiz
  ];
  home.persistence."/sync/home/bloodwolfe".directories = [
    ".local/share/PrismLauncher/instances"
    ".config/ferium"
    ".local/share/packwiz"
  ];
  home.persistence."/persist/home/bloodwolfe".directories = [
    ".local/share/PrismLauncher/libraries"
    ".local/share/PrismLauncher/assets"
  ];
  home.persistence."/persist/home/bloodwolfe".files = [
    ".local/share/PrismLauncher/prismlauncher.cfg"
    ".local/share/PrismLauncher/accounts.json"
    ".local/share/PrismLauncher/metacache"
  ];
}
