{
  config,
  inputs,
  pkgs,
  ...
}:
let
  stateDir = "/run/kopia-b2";
  configFile = "${stateDir}/repository.config";
  cacheDir = "/var/cache/kopia-b2";
  recoveryDir = "/srv/dr/snapshots";
  metricDir = "/var/lib/prometheus-node-exporter-text-files";
  accessKey = config.sops.secrets."b2-kopia-access-key".path;
  secretKey = config.sops.secrets."b2-kopia-secret-key".path;
  password = config.sops.secrets."kopia-repository-password".path;
  connect = pkgs.writeShellScript "kopia-b2-recovery-connect" ''
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
      --readonly \
      --bucket=tinywolfe-dr-b0ab27 \
      --endpoint=s3.us-east-005.backblazeb2.com \
      --prefix=kopia/
  '';
  restore = pkgs.writeShellScript "kopia-b2-recovery-restore" ''
    set -euo pipefail
    install -d -m 0700 ${recoveryDir}
    incoming="$(${pkgs.coreutils}/bin/mktemp -d ${recoveryDir}/incoming.XXXXXX)"
    trap 'rm -rf "$incoming"' EXIT
    KOPIA_PASSWORD="$(<${password})"
    export KOPIA_PASSWORD

    restore_path() {
      source=$1
      install -d -m 0700 "$incoming/$(${pkgs.coreutils}/bin/dirname "$source")"
      ${pkgs.kopia}/bin/kopia --config-file=${configFile} snapshot restore \
        --write-files-atomically \
        "root@navi:/backup/srv-staging/$source" "$incoming/$source"
    }

    restore_path .complete
    restore_path databases/auth.dump
    restore_path databases/vaultwarden.dump
    restore_path openbao.snap
    restore_path volumes/auth_data
    restore_path volumes/auth_custom_templates
    restore_path volumes/vaultwarden_data

    test -s "$incoming/.complete"
    ${pkgs.postgresql_18}/bin/pg_restore --list "$incoming/databases/auth.dump" >/dev/null
    ${pkgs.postgresql_18}/bin/pg_restore --list "$incoming/databases/vaultwarden.dump" >/dev/null
    ${pkgs.gzip}/bin/gzip -cd "$incoming/openbao.snap" |
      ${pkgs.gnutar}/bin/tar -tf - >/dev/null
    test -n "$(${pkgs.findutils}/bin/find "$incoming/volumes/auth_data" -mindepth 1 -print -quit)"
    test -n "$(${pkgs.findutils}/bin/find "$incoming/volumes/vaultwarden_data" -mindepth 1 -print -quit)"
    ${pkgs.coreutils}/bin/date --iso-8601=seconds >"$incoming/.restored-at"

    rm -rf ${recoveryDir}/previous
    if [[ -d ${recoveryDir}/current ]]; then
      mv ${recoveryDir}/current ${recoveryDir}/previous
    fi
    mv "$incoming" ${recoveryDir}/current
    trap - EXIT

    output=${metricDir}/kopia-recovery.prom
    printf 'kopia_recovery_last_success_unixtime %s\n' "$(${pkgs.coreutils}/bin/date +%s)" \
      >"$output.tmp"
    mv "$output.tmp" "$output"
    ${pkgs.coreutils}/bin/chmod 0644 "$output"
  '';
in
{
  sops = {
    defaultSopsFile = "${inputs.secrets}/sops/hosts/main-vps/system.yaml";
    secrets = {
      "b2-kopia-access-key" = { };
      "b2-kopia-secret-key" = { };
      "kopia-repository-password" = { };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
    "d ${cacheDir} 0700 root root -"
    "d ${recoveryDir} 0700 root root -"
    "d ${metricDir} 0755 root root -"
    "z ${metricDir}/kopia-recovery.prom 0644 root root -"
  ];

  systemd.services.kopia-b2-recovery = {
    description = "Stage the latest identity recovery inputs from immutable B2 storage";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      UMask = "0077";
      Environment = "HOME=${cacheDir}";
      ExecStartPre = connect;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        stateDir
        cacheDir
        recoveryDir
        metricDir
      ];
    };
    script = "exec ${restore}";
  };

  systemd.timers.kopia-b2-recovery = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 10:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.textfile.directory=${metricDir}" ];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
}
