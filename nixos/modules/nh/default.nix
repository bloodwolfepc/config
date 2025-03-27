{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "nh";
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keee-since 4d --keep 3";
      flake = "/home/bloodwolfe/src/config";
    };
    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nvd
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
