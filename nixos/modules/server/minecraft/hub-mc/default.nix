{ lib, pkgs, config, inputs, ... }: let
  mc-attrs = import ../mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "hub-mc";
    srvPackage = pkgs.papermc;
    netPortMinecraft = 25590;
    netHostAddress = "10.11.0.2";
    netLocalAddress = "10.11.0.102";
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
