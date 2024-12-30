{ lib, config, pkgs, ... }: let 
  #TODO extra sync and backup dirs
  #~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common
  #webfishing, fear and hunger

  #flatpak error with home manager gtk enabled:
  #bwrap: Can't make symlink at /home/bloodwolfe/.themes/adw-gtk3: existing destination is ../../../nix/store/qm2rssza1hl3w7d5jpm5f95kn2h30r7k-home-manager-files/.themes/adw-gtk3

  attrs = lib.custom.mkHomeApplication {
    name = "steam";
    key = "g";
    command = "${pkgs.alacritty}/bin/alacritty --command tmux";
    persistDirs = [
      ".local/share/Steam"
    ];
    pcWindowRule = let 
      adhere-workspace = "steam";
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
