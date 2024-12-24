{ lib, pkgs, config, inputs, ... }: let
  mc-attrs = import ../mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "vanilla-mc";
    srvPackage = pkgs.papermc;
    netHostAddress = "10.11.0.2";
    netLocalAddress = "10.11.0.102";
    extraServerConfig = {
      serverProperties = mc-attrs.server-properties.survival-default;
      files = {
        "ops.json".value = mc-attrs.ops;
        #"config/paper-global.yml" = lib.minecraft.toYAMLFile mc-attrs.paper.paper-global-default;
        "config/paper-global.yml".value = mc-attrs.paper.paper-global-default;
      };
    }; 
  };
in {
  inherit (attrs) options config;
}
