{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "bitwarden";
    packages = with pkgs; [
      bitwarden
      bitwarden-cli
    ];
    programs.rbw = {
      enable = true;
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
