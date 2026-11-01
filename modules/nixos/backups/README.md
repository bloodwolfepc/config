# Reusable snapshot-backed backups

Exports: `nixosModules.backups` and `homeManagerModules.backups`.
The shared modules and tests do not know which applications a machine runs.

## Declarations versus policy

The Home Manager module only declares and validates selections. An application
module can contribute a job, or merge more paths into an existing job:

```nix
home.backups.documents = {
  paths = [ "documents" ".config/example" ];
  exclude = [ "**/cache" ];
};
```

Paths are home-relative, not inferred from persistence. Declaring selections does
not enable backups, configure credentials, or install services.

A NixOS host imports the engine and supplies policy. For example:

```nix
services.snapshotBackups = {
  enable = true;
  source = "/persist";
  basePath = "/persist/home/sample";
  settings = {
    repository = "/mnt/backup/repository";
    passwordFile = "/run/secrets/backup-password";
  };
  jobs = config.home-manager.users.sample.home.backups;
};
```

A consumer without Home Manager can supply `jobs` directly. Relative selections
use `basePath`; native NixOS consumers can also select absolute paths inside the
source. Each job becomes an isolated native restic service/timer with a host label
and namespace-prefixed tag. Adding jobs needs no registration inside the engine.
Different machines can supply entirely different sources, users, jobs, schedules,
repositories and runtime credential files. The default namespace is the hostname.

`settings` supplies shared native restic configuration; per-job native overrides
support schedules, exclusions and preparation hooks. Initialization is deliberately
disabled, backup jobs always check, and pruning belongs only to guarded maintenance.
Use one repository/connection configuration per engine: per-job repository,
credential-file, environment and backend-option changes are rejected because
maintenance must open the same backend. Secret values must never be Nix literals; use native
`passwordFile`, `environmentFile`, `repositoryFile` and `rcloneConfigFile` options.
A host may set `requires` to units that supply those runtime files. Their
provisioning belongs to the host, not the shared engine.

## Prepared exports

`backupPrepareCommand` and `dynamicFilesFrom` use native restic hook semantics.
The Home Manager interface exposes the same fields for exceptional app-specific
exports. Such transformations belong beside the application, never in the engine.

`BACKUP_ROOT` points to `basePath` **inside the read-only snapshot**. Hooks read
there and write prepared output under the private `RUNTIME_DIRECTORY`.
`dynamicFilesFrom` prints additional output paths to upload. Both variables work
without embedding a username, home layout, application name or host in the engine.
Arbitrary hooks are trusted configuration and must not fall back to live data.

## Storage and operations

The source must be a declared Btrfs mount and snapshot jobs run as root.
Mount/snapshot paths use literal Btrbk-safe names (letters, digits, `/._@+-`);
status paths cannot contain whitespace and storage paths cannot contain systemd
specifiers. Selected data and base paths can contain spaces. Command-stream jobs
are not supported; prepared files use hooks instead. Shared exclusions are merged
with per-job exclusions, and maintenance never runs payload/export/cleanup hooks.

The adapter creates a fresh read-only
snapshot and refuses selected nested subvolumes (including hidden ancestors),
mount overlays and escaping wildcard symlinks. No live-data fallback is allowed.
Btrbk keeps the latest local staging snapshot per job; snapshots pin blocks, so
watch free space. Creation is refused below 10 GiB free. This headroom is not a
capacity guarantee during later writes. Filesystem snapshots are crash-consistent,
not a capture of unsaved application memory or a semantic recovery certification.

Shared repository commands queue with flock. Maintenance checks job states and
persistent failure/success markers **inside the lock**, checks the repository,
performs tag/host-scoped retention, then checks again. A partial or failed backup
blocks maintenance until a checked retry succeeds. Changing repository per job
would violate that policy; use a separate host/configuration instead.

Desktop notifications are optional through `notifyUser`; that account needs an
explicit UID. Without it, there is no user-bus dependency. These alerts only work
on the running machine, not as independent offline monitoring. Source, base,
snapshot and status paths are host policy. Preserve namespace, host labels,
repository and credential files when moving an existing configuration.

## Tests

`checks.<system>.backups-config` evaluates synthetic consumers with different
storage layouts, hostnames, job sets and notification choices, plus descriptor
merging and invalid-input/UID rejection. A disabled consumer installs no jobs.

`checks.<system>.backups-vm` runs synthetic data through real Btrfs, Btrbk, restic
and SQLite: open WAL writer recovery, post-snapshot writes, read-only enforcement,
prepared exports, spaces, per-job retention, unsupported-storage refusal, and a
failure gate changing while maintenance waits on the shared lock. No real
credentials, application profiles or remote repositories are used.
