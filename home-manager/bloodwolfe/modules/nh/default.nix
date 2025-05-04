{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "nh";
    packages = with pkgs; [
      nix-output-monitor
      nvd
    ];
    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/src/config";
      clean = {
        enable = true;
        extraArgs = "--keee-since 4d --keep 3";
      };
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
