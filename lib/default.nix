{ lib, ... }:
with lib;
with builtins;
rec {
  mkModule =
    {
      name,
      attrs ? { },
      config,
    }:
    let
      cfg = config.modules.${name};
    in
    mkIf cfg.enable attrs;
}
