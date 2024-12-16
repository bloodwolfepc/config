{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "neomutt";
    syncDirs = [
      "mail"
    ];
    inherit config;
    inherit extraConfig;
  }; 
  extraConfig = {
    programs.neomutt = {
      enable = true;
    };
  };
in {
  inherit (attrs) options config;
}
