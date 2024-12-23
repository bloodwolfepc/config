{ config, lib, pkgs, ... }: let
  mc-attrs = import ../defaults { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    srvName = "xyz-mc";
    package = pkgs.fabricServers.fabric;
    netHostAddress = "10.11.0.3";
    netLocalAddress = "10.11.0.103";
    extraServerConfig = {
      serverProperties = mc-attrs.server-properties.redstone-default;
      symlinks."mods" = with mc-attrs.mods; [
        fabric-proxy-lite
        worldedit
        carpet
      ];
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
