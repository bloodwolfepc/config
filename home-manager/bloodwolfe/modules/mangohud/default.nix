{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit lib;
  attrs = lib.custom.mkHomeApplication {
    name = "mangohud";
    programs.mangohud = {
      enable = true;
      enableSessionWide = true;
    };
    home.file.".config/MangoHud/MangoHod.conf".source = ./MangoHud.conf;
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
