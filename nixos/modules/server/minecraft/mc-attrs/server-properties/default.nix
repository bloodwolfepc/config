{
  server-properties = rec {
    superflat-default = {
      gamemode = "creative";
      difficulty = "normal";
      max-players = 12;
      #level-name = "Waterdreamer world.";
      motd = "Waterdreamer Minecraft Server.";
      simulation-distance = 4;
      view-distance = 7;
      spawn-protection = 0;
      enable-command-block = true;
      generate-structures = false;
      online-mode = false;
      allow-flight = true;
      allow-nether = false;
      enable-rcon = true;
      spawn-npcs = false;
      spawn-animals = false;
      spawn-monsters = false;
    };
    survival-default = superflat-default // {
      gamemode = "survival";
      spawn-protection = 12;
      generate-structures = false;
      allow-flight = false;
      allow-nether = true;
      spawn-npcs = true;
      spawn-animals = true;
      spawn-monsters = true;
    };
    redstone-default = superflat-default // {
      simulation-distance = 20;
    };
  };
}

/*
    mc-default = { #23w31a
      enable-jmx-monitoring = false;
      "rcon.port" = 25575;
      level-seed = "";
      gamemode = "survival";
      enable-command-block = false;
      enable-query = false;
      generator-settings = "{}";
      enforce-secure-profile = true;
      level-name = "world";
      motd = "A Minecraft Server";
      "query.port" = 25565;
      pvp = true;
      generate-structures = true;
      max-chained-neighbor-updates = 1000000;
      difficulty = "easy";
      network-compression-threshold = 256;
      max-tick-time = 60000;
      require-resource-pack = false;
      use-native-transport = true;
      max-players = 20;
      online-mode = true;
      enable-status = true;
      allow-flight = false;
      initial-disabled-packs = "";
      broadcast-rcon-to-ops = true;
      view-distance = 10;
      server-ip = "";
      resource-pack-prompt = "";
      allow-nether = true;
      server-port = 25565;
      enable-rcon= false;
      sync-chunk-writes = true;
      op-permission-level = 4;
      prevent-proxy-connections = false;
      hide-online-players = false;
      resource-pack = "";
      entity-broadcast-range-percentage = 100;
      simulation-distance=10;
      "rcon.password" = "";
      player-idle-timeout = 0;
      force-gamemode = false;
      rate-limit = 0;
      hardcore = false;
      white-list = false;
      broadcast-console-to-ops = true;
      spawn-npcs = true;
      spawn-animals = true;
      log-ips = true;
      function-permission-level = 2;
      initial-enabled-packs = "vanilla";
      level-type = "minecraft\:normal";
      text-filtering-config= "";
      spawn-monsters = true;
      enforce-whitelist = false;
      spawn-protection = 16;
      resource-pack-sha1 = "";
      max-world-size = 29999984;
    };
*/
