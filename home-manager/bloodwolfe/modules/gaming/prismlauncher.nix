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
  home.persistence."/persist".directories = [
    ".local/share/PrismLauncher"
  ];
}
