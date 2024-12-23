{ lib, pkgs, ... }: let
  mc-attrs = import ./mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftSearver {
    srv = {
      name = "vanilla-mc";
      package = pkgs.papermc;
      netHostAddress = "10.11.0.2";
      netLocalAddress = "10.11.0.102";
      extraServerConfig = {
        serverProperties = mc-attrs.server-properties.vanilla-default;
        files = {
          "ops.json".value = mc-attrs.ops;
          "config/paper-global.yml" = mc-attrs.paper.paper-global-default;
        };
      };
    };
  };
in {
  inherit (attrs) options config;
}
