{ lib, pkgs, config, inputs, ... }: let
  mc-attrs = import ../mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "bonefish-mc";
    srvPackage = pkgs.papermc;
    netPortMinecraft = 25593;
    netHostAddress = "10.11.0.5";
    netLocalAddress = "10.11.0.105";
    extraServerConfig = {
      serverProperties = mc-attrs.server-properties.survival-default;
      files = {
        "ops.json".value = mc-attrs.ops;
        "config/paper-global.yml".value = mc-attrs.paper.paper-global.modified;
      };
    }; 
  };
in {
  inherit (attrs) options config;
}
