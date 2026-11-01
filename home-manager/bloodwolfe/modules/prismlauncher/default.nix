{
  pkgs,
  lib,
  ...
}:
{
  home.backups.state = {
    paths = [
      ".local/share/PrismLauncher/instances/*/instance.cfg"
      ".local/share/PrismLauncher/instances/*/mmc-pack.json"
    ]
    ++
      lib.concatMap
        (
          root:
          map (part: ".local/share/PrismLauncher/instances/*/${root}/${part}") [
            "saves"
            "config"
            "scripts"
            "kubejs"
            "screenshots"
            "mods"
            "resourcepacks"
            "shaderpacks"
            "datapacks"
          ]
        )
        [
          ".minecraft"
          "minecraft"
        ];
    exclude = [ "**/PrismLauncher/instances/.*" ];
  };
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
