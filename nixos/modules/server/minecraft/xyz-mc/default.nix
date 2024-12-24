{ config, lib, pkgs, inputs, ... }: let
  mc-attrs = import ../mc-attrs { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "xyz-mc";
    srvPackage = pkgs.fabricServers.fabric;
    netHostAddress = "10.11.0.3";
    netLocalAddress = "10.11.0.103";
    extraServerConfig = {
      serverProperties = mc-attrs.server-properties.redstone-default;
      #symlinks."mods" = pkgs.linkFarmFromDrvs "mods" (with mc-attrs.mods; [
      #  fabric-proxy-lite
      #  worldedit
      #  carpet
      #]);
      symlinks = {
        "mods" = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
          fabric-proxy-lite = mc-attrs.mods.fabric-proxy-lite;
          worldedit = mc-attrs.mods.worldedit;
          carpet = mc-attrs.mods.carpet;
        });
      };
      files = {
        "ops.json".value = mc-attrs.ops;
        "config/FabricProxy-Lite.toml" = mc-attrs.modconfig.fabric-proxy-lite;
        "whitelist.json".value = mc-attrs.ops;
      };
    };
  };
in {
  inherit (attrs) config options;
}
