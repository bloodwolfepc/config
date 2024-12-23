{ pkgs, lib, ... }: let
  attrs = lib.minecraft.mkMinecraftServer {
    srvName = "proxy-mc";
    srvMotd =  "<#09add3>never knows best.";
    package = pkgs.velocityServers.velocity;
    NetHostAddress = "10.11.0.1";
    NetLocalAddress = "10.11.0.101";
    extraServerConfig = {
      files."velocity.toml".value = velocity-toml;
    };
  };
  velocity-toml = {
    servers = {
      vanilla-mc = "10.11.0.2";
      xyx-mc = "10.11.0.3";
    };
    config-version = "2.7";
    bind = "0.0.0.0:${attrs.netMinecraftPort}";
    motd = "${attrs.srvMotd}";
    show-max-players = 100;
    online-mode = true;
    force-key-authentication = false;
    prevent-client-proxy-connections = false;
    player-info-forwarding-mode = "modern";
    forwarding-secret-file = "forwarding.secret";
    announce-forge = true;
    kick-existing-players = false;
    ping-passthrough = "DISABLED";
    enable-player-address-logging = true;
    try = [
      "vanilla-mc"
    ];
    forced-hosts = {
      "localhost" = [
        "vanilla-mc"
      ];
    };
    advanced = {
      compression-threshold = 256;
      compression-level = "-1";
      login-ratelimit = 3000;
      connection-timeout = 5000;
      read-timeout = 30000;
      haproxy-protocol = false;
      tcp-fast-open = false;
      bungee-plugin-message-channel = true;
      show-ping-requests = false;
      failover-on-unexpected-server-disconnect = true;
      announce-proxy-commands = true;
      log-command-executions = false;
      log-player-connections = true;
      accepts-transfers = false;
    };
    query = {
      enabled = false;
      port = attrs.netPortsMinecraft;
      map = "Velocity";
      show-plugins = true;
    };  
  };
in {
  inherit (attrs) config options;
}
