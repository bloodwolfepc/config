{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "steam";
    persistDirs = [
      ".local/share/Steam"
    ];
    pcWindowRule = let 
      adhere-workspace = "5";
    in [
      "float, class:^([Ss]team)$, title:^((?![Ss]team).*)$"
      "tile, class:^([Ss]team)$, title:^([Ss]team)$"
      "workspace name:${adhere-workspace} silent, class:^([Ss]team)$, title:^([Ss]team)$"
      "workspace name:${adhere-workspace} silent, class:^([Ss]special [Oo]ffers)$, title:^([Ss]special [Oo]ffers)$"
      "workspace name:${adhere-workspace} silent, class:^([Ss]ign [Ii]n [Tt]o [Ss]team)$, title:^([Ss]ign [Ii]n [Tt]o [Ss]team)$"
    ];
    inherit config;
  };
in {
  inherit (attrs) options config;
}
