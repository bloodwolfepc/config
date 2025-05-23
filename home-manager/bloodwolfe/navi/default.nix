{
  lib,
  config,
  inputs,
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
        srv-progs
        ;
      enable = {
        list = [ ] ++ require-nixos ++ require-hm ++ srv-progs;
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
      sops.secrets = {
        "syncthing-key-navi" = { };
        "syncthing-cert-navi" = { };
      };
      services.syncthing = {
        key = config.sops.secrets."syncthing-key-navi".path;
        cert = config.sops.secrets."syncthing-cert-navi".path;
      };
    };
}
