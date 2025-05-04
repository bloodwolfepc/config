{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "cliphist";
    packages = with pkgs; [
      grimblast
      wl-clipboard
    ];
    inherit config;
    services.cliphist = {
      enable = true;
    };
  };
in
{
  inherit (attrs) options config;
}
