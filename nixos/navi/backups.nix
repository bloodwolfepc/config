{ config, pkgs, ... }:
let
  backupPromote = pkgs.writeShellScript "srv-backup-promote" ''
    set -euo pipefail
    exec 9>/run/lock/srv-backup.lock
    ${pkgs.util-linux}/bin/flock 9
    [[ -f /backup/srv-incoming/.complete ]] || exit 0
    rm -rf /backup/srv-previous
    [[ ! -d /backup/srv-staging ]] || mv /backup/srv-staging /backup/srv-previous
    mv /backup/srv-incoming /backup/srv-staging
    install -d -o srv-backup -g srv-backup -m 0700 /backup/srv-incoming
    rm -rf /backup/srv-previous
  '';
  qcowMetrics = pkgs.writeShellScript "srv-qcow-metrics" ''
    set -euo pipefail
    output=/var/lib/prometheus-node-exporter-text-files/srv-qcow.prom
    tmp="$output.tmp"
    : >"$tmp"
    for disk in /srv/libvirt/srv/{srv-data,admin-data}.qcow2 /var/lib/libvirt/images/srv/{srv,admin}-root-*.qcow2; do
      [[ -f "$disk" ]] || continue
      volume="$(basename "$disk")"
      name="''${volume%.qcow2}"
      pool=srv
      [[ "$name" != *-data ]] || pool=srv-data
      info="$(${pkgs.libvirt}/bin/virsh -c qemu:///system vol-info --pool "$pool" "$volume" --bytes)"
      allocated="$(${pkgs.gawk}/bin/awk '/^Allocation:/ { print $2 }' <<<"$info")"
      virtual="$(${pkgs.gawk}/bin/awk '/^Capacity:/ { print $2 }' <<<"$info")"
      printf 'srv_qcow_allocated_bytes{disk="%s"} %s\n' "$name" "$allocated" >>"$tmp"
      printf 'srv_qcow_virtual_bytes{disk="%s"} %s\n' "$name" "$virtual" >>"$tmp"
    done
    mv "$tmp" "$output"
  '';
in
{
  sops.secrets.borg-pass = { };

  users.groups.srv-backup = { };
  users.users.srv-backup = {
    isSystemUser = true;
    group = "srv-backup";
    home = "/backup/srv-incoming";
  };
  systemd.tmpfiles.rules = [
    "d /backup/srv-incoming 0700 srv-backup srv-backup -"
    "d /backup/srv-staging 0700 srv-backup srv-backup -"
    "d /var/lib/prometheus-node-exporter-text-files 0755 root root -"
  ];

  services.rsyncd = {
    enable = true;
    settings = {
      globalSection = {
        address = "0.0.0.0";
        uid = "srv-backup";
        gid = "srv-backup";
        "use chroot" = true;
      };
      sections.srv-incoming = {
        path = "/backup/srv-incoming";
        "read only" = false;
        "hosts allow" = "100.64.0.4";
      };
    };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    873
    9100
  ];

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files" ];
  };
  systemd.services.srv-backup-promote = {
    description = "Atomically publish a completed service backup";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupPromote;
    };
  };
  systemd.paths.srv-backup-promote = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/backup/srv-incoming/.complete";
  };

  systemd.services.srv-qcow-metrics = {
    description = "Export service VM QCOW2 allocation metrics";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = qcowMetrics;
    };
  };
  systemd.timers.srv-qcow-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
    };
  };

  services.borgbackup.jobs = {
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
    "srv-vm" = {
      paths = "/backup/srv-staging";
      repo = "/backup/srv";
      compression = "auto,zstd";
      startAt = "*-*-* 04:00";
      doInit = true;
      preHook = ''
        exec 9>/run/lock/srv-backup.lock
        ${pkgs.util-linux}/bin/flock 9
        test -f /backup/srv-staging/.complete
      '';
      prune.keep = {
        daily = 7;
        weekly = 5;
        monthly = 12;
      };
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borg-pass.path}";
      };
    };
  };
}
