{ config, lib, pkgs, inputs, ... }: let
  mc-attrs = import ../mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "yuis-mc";
    srvPackage = pkgs.fabricServers.fabric;
    netPortMinecraft = 25594;
    netHostAddress = "10.11.0.6";
    netLocalAddress = "10.11.0.106";
    extraServerConfig = {
      serverProperties = mc-attrs.server-properties.redstone-default;
      symlinks = {
        "mods" = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
          fabric-proxy-lite = mc-attrs.mods.fabric-proxy-lite;
          worldedit = mc-attrs.mods.worldedit;
          carpet = mc-attrs.mods.carpet;
        });
      };
      files = {
        "ops.json".value = mc-attrs.ops;
        "whitelist.json".value = mc-attrs.ops;
        "config/FabricProxy-Lite.toml" = mc-attrs.modconfig.fabric-proxy-lite;
      };
    };
  };
in {
  inherit (attrs) config options;
}
