{ pkgs, lib, config, inputs, ... }: let
  mc-attrs = import ../defaults { inherit pkgs; };
  attrs = lib.minecraft.mkMinecraftServer {
    inherit config inputs;
    srvName = "velocity-mc";
    srvMotd =  "<#09add3>never knows best.";
    srvPackage = pkgs.velocityServers.velocity;
    mcWorlds = [ ];
    netPortMinecraft = 25565;
    netHostAddress = "10.11.0.1";
    netLocalAddress = "10.11.0.101";
    extraServerConfig = {
      files."velocity.toml".value = velocity-toml;
    };
  };
  velocity-toml = {
    servers = {
      hub-mc = "10.11.0.2:25590";
      vanilla-mc = "10.11.0.3:25591";
      xyz-mc = "10.11.0.4:25592";
      bonefish-mc = "10.11.0.5:25593";
      yuis-mc = "10.11.0.6:25594";
      try = [
        "hub-mc"
        "vanilla-mc"
        "xyz-mc"
        "bonefish-mc"
        "yuis-mc"
      ];
    };
    config-version = "2.7";
    bind = "0.0.0.0:25565";
    motd =  "<#09add3>never knows best.";
    #forwarding-secret-file = "forwarding.secret";
    forwarding-secret = "ExampleForwardingSecret";
    #show-max-players = 100;
    online-mode = true;
    force-key-authentication = false;
    prevent-client-proxy-connections = false;
    player-info-forwarding-mode = "modern";
    #announce-forge = true;
    #kick-existing-players = false;
    #ping-passthrough = "DISABLED";
    #enable-player-address-logging = true;
    forced-hosts = {
      "localhost" = [
        "hub-mc"
      ];
    };
    #advanced = {
    #  compression-threshold = 256;
    #  compression-level = "-1";
    #  login-ratelimit = 3000;
    #  connection-timeout = 5000;
    #  read-timeout = 30000;
    #  haproxy-protocol = false;
    #  tcp-fast-open = false;
    #  bungee-plugin-message-channel = true;
    #  show-ping-requests = false;
    #  failover-on-unexpected-server-disconnect = true;
    #  announce-proxy-commands = true;
    #  log-command-executions = false;
    #  log-player-connections = true;
    #  accepts-transfers = true;
    #};
    query = {
      enabled = true;
      port = 25565;
    #  map = "Velocity";
    #  show-plugins = true;
    };  
  };
in {
  inherit (attrs) config options;
}

  #velocity-toml = pkgs.writeTextFile {
  #  name = "velocity.toml";
  #  text = ''
  #    config-version = "2.7"
  #    bind = "0.0.0.0:25565"
  #    motd = "<#09add3>never knows best.."
  #    show-max-players = 100
  #    online-mode = true
  #    force-key-authentication = false
  #    prevent-client-proxy-connections = false
  #    player-info-forwarding-mode = "modern"
  #    forwarding-secret-file = "forwarding.secret"
  #    announce-forge = true
  #    kick-existing-players = false
  #    ping-passthrough = "DISABLED"
  #    enable-player-address-logging = true
  #    [servers]
  #     vanilla-mc = "192.168.100.3:25565"
  #     xyx-mc = "192.168.100.4:"
  #    try = [
  #     "vanilla-mc"
  #    ]
  #    [forced-hosts]
  #    "localhost" = [
  #     "vanilla-mc"
  #    ]
  #    [advanced]
  #    compression-threshold = 256
  #    compression-level = -1
  #    login-ratelimit = 3000
  #    connection-timeout = 5000
  #    read-timeout = 30000
  #    haproxy-protocol = false
  #    tcp-fast-open = false
  #    bungee-plugin-message-channel = true
  #    show-ping-requests = false
  #    failover-on-unexpected-server-disconnect = true
  #    announce-proxy-commands = true
  #    log-command-executions = false
  #    log-player-connections = true
  #    accepts-transfers = false
  #    [query]
  #    enabled = false
  #    port = 25565
  #    map = "Velocity"
  #    show-plugins = false
  #  ;
  #
