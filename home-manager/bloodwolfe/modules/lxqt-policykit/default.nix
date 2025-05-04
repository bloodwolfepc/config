{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "lxqt-policykit";
    packages = with pkgs; [
      lxqt.lxqt-policykit
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
