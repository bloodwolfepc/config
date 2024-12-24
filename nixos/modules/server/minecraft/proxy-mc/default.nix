{ pkgs, lib, config, inputs, ... }: let
  mc-attrs = import ../defaults { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "proxy-mc";
    srvMotd =  "<#09add3>never knows best.";
    srvPackage = pkgs.velocityServers.velocity;
    netHostAddress = "10.11.0.1";
    netLocalAddress = "10.11.0.101";
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
    bind = "0.0.0.0:25565";
    motd =  "<#09add3>never knows best.";
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
      port = 25565;
      map = "Velocity";
      show-plugins = true;
    };  
  };
in {
  inherit (attrs) config options;
}
