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
  home.persistence."/persist/home/bloodwolfe".directories = [
    ".local/share/PrismLauncher"
  ];
}
