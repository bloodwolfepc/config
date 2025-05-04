{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "fd";
    inherit config;
    programs.fd = {
      enable = true;
    };
  };
in
{
  inherit (attrs) options config;
}
