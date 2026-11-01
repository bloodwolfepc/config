# Small filesystem adapter around native services.restic.backups.
# Job attributes are ordinary NixOS restic options; paths refer to the live source.
{ source, jobs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  snapshotBase = "${source}/.angel-backup-snapshots";
  helper = pkgs.writeShellApplication {
    name = "restic-btrfs-view";
    runtimeInputs = [
      pkgs.btrbk
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.findutils
      pkgs.util-linux
      pkgs.jq
    ];
    text = builtins.readFile ./snapshot.sh;
  };
  runtime = name: "/run/restic-backups-${name}";
  relative = path: lib.removePrefix "${source}/" path;
  prefix =
    path:
    let
      start = builtins.head (builtins.split "[*?\\[]" (relative path));
    in
    if start == relative path then
      start
    else if lib.hasSuffix "/" start then
      lib.removeSuffix "/" start
    else
      builtins.dirOf start;
  btrbkConfig =
    name:
    pkgs.writeText "btrbk-${name}.conf" ''
      backend btrfs-progs
      lockfile ${runtime name}/btrbk.lock
      timestamp_format long-iso
      snapshot_preserve_min latest
      snapshot_preserve no
      volume ${source}
        snapshot_dir ${snapshotBase}/${name}
        subvolume .
          snapshot_name ${name}
          snapshot_create always
    '';
in
{
  assertions = [
    {
      assertion = config.fileSystems.${source}.fsType == "btrfs";
      message = "Snapshot backups require a declared Btrfs source mount";
    }
    {
      assertion = lib.all (name: builtins.match "[a-zA-Z0-9_-]+" name != null) (builtins.attrNames jobs);
      message = "Unsafe snapshot backup job name";
    }
    {
      assertion = lib.all (
        job:
        lib.all (
          path:
          lib.hasPrefix "${source}/" path && !(lib.hasPrefix snapshotBase path) && !(lib.hasInfix "\n" path)
        ) job.paths
      ) (builtins.attrValues jobs);
      message = "Backup paths must be inside the snapshot source, outside its snapshot namespace";
    }
  ];
  systemd.tmpfiles.rules = [
    "d ${snapshotBase} 0700 root root -"
  ]
  ++ lib.mapAttrsToList (name: _: "d ${snapshotBase}/${name} 0700 root root -") jobs;
  environment.systemPackages = [
    pkgs.btrbk
    pkgs.btrfs-progs
  ];
  services.restic.backups = lib.mapAttrs (
    name: job:
    job
    // {
      initialize = false;
      paths = map (path: "${runtime name}/view/${relative path}") job.paths;
      backupPrepareCommand = ''
        #!${pkgs.runtimeShell}
        set -Eeuo pipefail
        ${lib.getExe helper} ${
          lib.escapeShellArgs (
            [
              (toString (btrbkConfig name))
              source
              "${snapshotBase}/${name}"
              "${runtime name}/view"
              name
            ]
            ++ lib.concatMap (path: [
              (prefix path)
              (relative path)
            ]) job.paths
          )
        }
        ${job.backupPrepareCommand or ""}
      '';
    }
  ) jobs;
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "restic-backups-${name}" {
      unitConfig.RequiresMountsFor = [ source ];
      serviceConfig = {
        UMask = "0077";
        RuntimeDirectoryMode = "0700";
        TimeoutStartSec = "6h";
        Nice = 10;
        IOSchedulingClass = "idle";
      };
    }
  ) jobs;
}
