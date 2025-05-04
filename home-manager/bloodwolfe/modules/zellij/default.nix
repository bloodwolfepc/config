{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "zellij";
    programs.zellij = {
      enable = true;
      #enableZshIntegration = true;
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
