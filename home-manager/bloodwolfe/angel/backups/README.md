# Angel cloud backup policy

Applications stay open. Five isolated native restic jobs read read-only Btrfs
snapshots; the existing Nextcloud repository, password, host/tag identities and
selected data are preserved.

## Ownership

- Application modules declare `home.backups.JOB.paths` and `exclude` beside their
  package/settings/persistence. Paths are home-relative; exclusions are native
  restic patterns. Persistence does **not** imply cloud backup.
- `modules/home-manager/backups/` defines the reusable selection interface and
  optional native preparation/export hooks. It installs no backup services.
- `modules/nixos/backups/` owns the application-agnostic engine and synthetic
  tests. See its README for the reusable API, guarantees and limitations.
- `nixos/angel/backups/default.nix` supplies this host's repository, runtime
  credential transport, source/base path, notification recipient and staggered
  scheduling policy. It contains no application-specific transformations.

Both shared modules are exported as `homeManagerModules.backups` and
`nixosModules.backups`. Other machines can import them with different users,
source mounts, data selections, repositories and schedules; importing app
selections on Navi does not enable Angel's cloud jobs.

## Existing coverage

The job names and restic tags remain `angel-GROUP`, with host `angel`:

- `state`: art projects; GIMP/Krita/BeeRef settings/resources; Ardour 8/9 and
  Carla/falkTX; Fcitx; Zathura SQLite/WAL; sanitized Millennium preferences/CSS;
  selected Prism instance metadata, saves, configuration, scripts, mods and packs.
  These app modules contribute normally merged lists to the existing state job.
- `legcord`: full profile except regenerable caches, diagnostics and runtime locks.
- `anki`: collections, media, add-ons/settings and profile configuration, with WAL.
- `firefox`: current/legacy full profile roots, including authentication/history,
  extensions and website storage. Ordinary caches/crashes/locks are excluded;
  IndexedDB is not trimmed in this migration.
- `terraria`: native Terraria/tModLoader and Steam userdata/Proton saves for app
  IDs 105600 and 1281930. Separate Flatpak storage is not included: its legacy
  save locations were empty after removal. Reintroducing it needs a snapshot source.

Dedicated credential stores, recovery keys, mail/contacts/calendars, Taskwarrior,
private AI history and Mozc learned state remain outside selections. Full profiles
intentionally include private authentication/history. Reauthentication can still
be required for expired/device-bound sessions.

The one specialized transformation now lives in the Steam module beside its data:
a jq whitelist excludes Millennium's network/proxy-credentials block. It reads
`BACKUP_ROOT` inside the snapshot and writes `millennium.json` under the private
runtime directory. Merge those preferences back rather than replacing a newer
full configuration. The engine/tests know nothing about this application.

## Host operation

Jobs retain their daily 03:00/10/20/30/40 schedule, jitter and persistent catch-up.
Failures retry after 30 minutes; ordinary sleep is not inhibited. Shared commands
queue under flock. Weekly maintenance checks recorded job health under that lock,
checks the repository, applies 7 daily / 4 weekly / 6 monthly retention scoped to
this host's tags, and checks again. Failed/partial attempts block pruning until
checked retries succeed.

The host credential bridge uses existing user SOPS secrets and an explicit UID
1000, matching the existing account. Backup-only credentials are cached atomically
in root-private `/run/angel-backup-credentials` (directory 0700, files 0600), survive
logout during uploads, and disappear at reboot. No password rotation/enrollment or
plaintext secret in Nix store/arguments/logs is involved. Other hosts may instead
provide native runtime credential files directly, without this bridge.

Root wrappers remain `restic-angel-GROUP`. The old `angel-state-backup` CLI is
retired. Old snapshots remain readable; new paths use the stable
`/run/restic-backups-angel-GROUP/view/home/bloodwolfe/...` tree. Restore into a
fresh private directory: native restic can merge into an existing destination.

Local snapshots are not recursive across nested subvolumes or mount overlays.
Selected unsupported layouts and escaping wildcard symlinks fail closed. Btrbk
retains a latest local staging snapshot per job, pinning old blocks; monitor free
space. These are crash-consistent views, not unsaved memory or certified semantic
app recovery. Desktop notifications are local, not independent offline monitoring.

## Review and verification

Use the reviewed `/tmp/deploy-angel-backup-modules` helper for this complete diff,
including the pending UID repair. Earlier helpers freeze older diffs and must not
be reused. Human review, hardware signing/push and privileged activation remain
required. No automatic initialization, app closure, data cleanup, boot-generation
pruning or `/sync` subvolume deletion is part of the helper.

The shared checks are `checks.<system>.backups-config` (different synthetic
consumers, selection merging, UID/bus/disabled behavior and invalid inputs) and
`checks.<system>.backups-vm` (real Btrfs/restic/SQLite and prepared exports using
synthetic datasets). Tests contain no actual application/host selections. Validate
all three real system profiles and build Angel separately; compare the existing
job selections/policy during migration. Live credential access, actual uploads,
payload restores and recovered application startup still require operational
verification after human deployment.
