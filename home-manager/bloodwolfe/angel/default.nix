{ pkgs, config, ... }:
let
  nc-sync-cloud = (
    pkgs.writeShellScriptBin "nc-sync-cloud" ''
      USERNAME="$(cat ${config.sops.secrets.cloud-waterdreamer-net-username.path})"
      PASSWORD="$(cat ${config.sops.secrets.cloud-waterdreamer-net-password.path})"
      ${pkgs.nextcloud-client}/bin/nextcloudcmd -h \
      --user "$USERNAME" \
      --password "$PASSWORD" \
      --path /cloud /persist/home/bloodwolfe/cloud \
      https://cloud.waterdreamer.net
    ''
  );
  nc-sync-notes = (
    pkgs.writeShellScriptBin "nc-sync-notes" ''
      USERNAME="$(cat ${config.sops.secrets.cloud-waterdreamer-net-username.path})"
      PASSWORD="$(cat ${config.sops.secrets.cloud-waterdreamer-net-password.path})"
      ${pkgs.nextcloud-client}/bin/nextcloudcmd -h \
      --user "$USERNAME" \
      --password "$PASSWORD" \
      --path /notebook /persist/home/bloodwolfe/notebook \
      https://cloud.waterdreamer.net
    ''
  );
in
{
  imports = [
    ../modules
  ];
  sops.secrets."cloud-waterdreamer-net-username" = { };
  sops.secrets."cloud-waterdreamer-net-password" = { };
  home.packages =
    with pkgs;
    [
      nextcloud-client
      xf86_input_wacom
      wine
      spotify
      wiremix
    ]
    ++ [
      nc-sync-cloud
      nc-sync-notes
    ];

  systemd.user = {
    services.nextcloud-autosync = {
      Unit = {
        Description = "Auto sync Nextcloud";
        After = "network-online.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${nc-sync-notes}/bin/nc-sync-notes";
        TimeoutStopSec = "180";
        KillMode = "process";
        KillSignal = "SIGINT";
      };
      Install.WantedBy = [ "multi-user.target" ];
    };
    timers.nextcloud-autosync = {
      Unit.Description = "Automatic sync files with Nextcloud when booted up after 5 minutes then rerun every 10 minutes";
      Timer.OnBootSec = "5min";
      Timer.OnUnitActiveSec = "10min";
      Install.WantedBy = [
        "multi-user.target"
        "timers.target"
      ];
    };
    startServices = true;
  };
  home.persistence = {
    "/persist".directories = [
      "cloud"
      "notebook"
    ];
  };

}

#   device = {
#     name = "wacom-intuos-pro-m-pen"
# };
