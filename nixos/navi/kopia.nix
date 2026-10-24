{ config, pkgs, ... }:
let
  stateDir = "/run/kopia-b2";
  configFile = "${stateDir}/repository.config";
  cacheDir = "/var/cache/kopia-b2";
  metricDir = "/var/lib/prometheus-node-exporter-text-files";
  accessKey = config.sops.secrets."b2-kopia-access-key".path;
  secretKey = config.sops.secrets."b2-kopia-secret-key".path;
  password = config.sops.secrets."kopia-repository-password".path;
  connect = pkgs.writeShellScript "kopia-b2-connect" ''
    set -euo pipefail
    install -d -m 0700 ${stateDir} ${cacheDir}
    rm -f ${configFile}
    AWS_ACCESS_KEY_ID="$(<${accessKey})"
    AWS_SECRET_ACCESS_KEY="$(<${secretKey})"
    KOPIA_PASSWORD="$(<${password})"
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY KOPIA_PASSWORD
    exec ${pkgs.kopia}/bin/kopia repository connect s3 \
      --config-file=${configFile} \
      --cache-directory=${cacheDir} \
      --no-persist-credentials \
      --bucket=tinywolfe-dr-b0ab27 \
      --endpoint=s3.us-east-005.backblazeb2.com \
      --prefix=kopia/
  '';
  initialize = pkgs.writeShellScript "kopia-b2-initialize" ''
    set -euo pipefail
    install -d -m 0700 ${stateDir} ${cacheDir}
    rm -f ${configFile}
    AWS_ACCESS_KEY_ID="$(<${accessKey})"
    AWS_SECRET_ACCESS_KEY="$(<${secretKey})"
    KOPIA_PASSWORD="$(<${password})"
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY KOPIA_PASSWORD
    if ! ${connect}; then
      rm -f ${configFile}
      ${pkgs.kopia}/bin/kopia repository create s3 \
        --config-file=${configFile} \
        --cache-directory=${cacheDir} \
        --no-persist-credentials \
        --bucket=tinywolfe-dr-b0ab27 \
        --endpoint=s3.us-east-005.backblazeb2.com \
        --prefix=kopia/ \
        --retention-mode=COMPLIANCE \
        --retention-period=30d
    fi
    ${pkgs.kopia}/bin/kopia --config-file=${configFile} policy set --global \
      --compression=zstd-fastest \
      --keep-latest=3 \
      --keep-daily=14 \
      --keep-weekly=8 \
      --keep-monthly=12 \
      --keep-annual=3
    ${pkgs.kopia}/bin/kopia --config-file=${configFile} maintenance set \
      --owner=root@navi \
      --enable-quick=true \
      --quick-interval=24h \
      --enable-full=true \
      --full-interval=7d \
      --extend-object-locks=true
    ${pkgs.kopia}/bin/kopia --config-file=${configFile} repository status
  '';
  snapshot = pkgs.writeShellScript "kopia-b2-snapshot" ''
    set -euo pipefail
    exec 9>/run/lock/srv-backup.lock
    ${pkgs.util-linux}/bin/flock 9
    test -s /backup/srv-staging/.complete
    KOPIA_PASSWORD="$(<${password})"
    export KOPIA_PASSWORD
    ${pkgs.kopia}/bin/kopia --config-file=${configFile} snapshot create \
      --fail-fast --json /backup/srv-staging
    output=${metricDir}/kopia-offsite-backup.prom
    printf 'kopia_offsite_backup_last_success_unixtime %s\n' "$(${pkgs.coreutils}/bin/date +%s)" \
      >"$output.tmp"
    mv "$output.tmp" "$output"
    ${pkgs.coreutils}/bin/chmod 0644 "$output"
  '';
  maintenance = pkgs.writeShellScript "kopia-b2-maintenance" ''
    set -euo pipefail
    exec 9>/run/lock/srv-backup.lock
    ${pkgs.util-linux}/bin/flock 9
    KOPIA_PASSWORD="$(<${password})"
    export KOPIA_PASSWORD
    ${pkgs.kopia}/bin/kopia --config-file=${configFile} maintenance run --full
    output=${metricDir}/kopia-offsite-maintenance.prom
    printf 'kopia_offsite_maintenance_last_success_unixtime %s\n' "$(${pkgs.coreutils}/bin/date +%s)" \
      >"$output.tmp"
    mv "$output.tmp" "$output"
    ${pkgs.coreutils}/bin/chmod 0644 "$output"
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    UMask = "0077";
    Environment = "HOME=${cacheDir}";
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ReadWritePaths = [
      stateDir
      cacheDir
      metricDir
      "/run/lock/srv-backup.lock"
    ];
  };
in
{
  sops.secrets = {
    "b2-kopia-access-key" = { };
    "b2-kopia-secret-key" = { };
    "kopia-repository-password" = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
    "d ${cacheDir} 0700 root root -"
    "f /run/lock/srv-backup.lock 0600 root root -"
    "z ${metricDir}/kopia-offsite-backup.prom 0644 root root -"
    "z ${metricDir}/kopia-offsite-maintenance.prom 0644 root root -"
  ];

  systemd.services = {
    kopia-b2-initialize = {
      description = "Initialize the immutable B2 Kopia repository";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = serviceConfig;
      script = "exec ${initialize}";
    };
    kopia-b2-backup = {
      description = "Back up the service snapshot to immutable B2 storage";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = serviceConfig // {
        ExecStartPre = connect;
        ReadOnlyPaths = [ "/backup/srv-staging" ];
      };
      script = "exec ${snapshot}";
    };
    kopia-b2-maintenance = {
      description = "Run full Kopia maintenance and renew B2 Object Locks";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = serviceConfig // {
        ExecStartPre = connect;
      };
      script = "exec ${maintenance}";
    };
  };

  systemd.timers = {
    kopia-b2-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 06:00:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    kopia-b2-maintenance = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 09:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
