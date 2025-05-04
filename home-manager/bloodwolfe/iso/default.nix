{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ../setup
  ];
  config =
    let
      inherit (config.globals.list)
        require-nixos
        require-hm
        require-pc
        ;
      enable = {
        list = [ ] ++ require-nixos ++ require-hm ++ require-pc;
        value = {
          enable = true;
          sync.enable = true;
          persist.enable = true;
        };
      };
      bwcfg = lib.listToAttrs (
        map (name: {
          inherit name;
          inherit (enable) value;
        }) enable.list
      );
    in
    {
      inherit bwcfg;
      enableMinimalNeovim = true;
    };
}
