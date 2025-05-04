{ config, ... }:
{
  sops.secrets.borg-pass = { };
  services.borgbackup.jobs = {
    "docker-bu" = {
      paths = "/docker";
      repo = "/backup/docker";
      compression = "auto,lzma";
      startAt = "0/4:00:00";
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-pass.path}";
      };
    };
    "sync-bu" = {
      paths = "/sync";
      repo = "/backup/sync";
      compression = "auto,lzma";
      startAt = "daily";
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-pass.path}";
      };
    };
    "persist-bu" = {
      paths = "/persist";
      repo = "/backup/persist";
      compression = "auto,lzma";
      startAt = "daily";
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-pass.path}";
      };
    };
    "minecraft-bu" = {
      paths = "/data/minecraft";
      repo = "/backup/persist";
      compression = "auto,lzma";
      startAt = "0/4:00:00";
      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.sops.secrets.borg-pass.path}";
      };
    };
  };
}
