{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "thefuck";
    programs.thefuck = {
      enable = true;
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
