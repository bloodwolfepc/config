# Angel snapshot backups

**Applications stay open.** Native NixOS `services.restic.backups` jobs read
read-only Btrfs snapshots created/retained by Btrbk. There is no Python backup
application and no resticprofile layer.

## Configuration

- `nixos/angel/backups/paths.nix`: ordinary source paths and exclusions. Add paths
  here; no script changes are needed. Paths refer to physical data under `/persist`,
  not the live `/home` bind mounts. Native restic files-from wildcard patterns
  select Steam accounts and Minecraft instances without discovery code.
- `nixos/angel/backups/default.nix`: repository/credentials, schedules, tags,
  maintenance and notifications using native NixOS restic options.
- `nixos/angel/backups/snapshot-restic.nix` and `snapshot.sh`: the small common
  filesystem adapter. It creates a fresh snapshot, verifies it is read-only and
  publishes a stable source path for the native job. It never copies profiles.
- Home Manager retains the existing SOPS password declaration and art/legacy
  state persistence only. Old user backup services/CLI are retired.

## Consistency and local snapshots

Each group gets its own snapshot of `/persist`, under the root-private
`/persist/.angel-backup-snapshots/angel-GROUP/`. Btrbk retains **one latest local
snapshot per group**, replacing only that group's older snapshots on its next
run. These are staging/recovery views, not substitutes for off-machine backups.
They include the entire source subvolume locally, but **only configured paths
are uploaded**. Secret stores, recovery keys, VM state and other excluded data
are not implicitly added to the cloud backup.

Snapshots are **crash-consistent**, not application-native exports: database,
WAL and journal files are captured together. They cannot capture unsaved data
still only in application memory. Application recovery may discard unfinished
transactions or require logging in again. The real Btrfs VM test verifies an
actively open SQLite WAL database restores the committed state at snapshot time,
not writes made afterward; it does not certify every application's recovery.

Snapshots initially share blocks rather than copying all data. Live writes keep
old blocks pinned, so local disk usage can grow (notably with Steam/VM updates).
The adapter refuses creation below 10 GiB free; this is headroom, not a guarantee
against filling the filesystem during large subsequent writes. Watch free space.

A parent snapshot does not capture nested subvolumes or mounted filesystems.
Selected prefixes are checked for mount overlays and inode-2 nested-subvolume
stubs; unsupported layouts **fail before backup**, never silently read live data.
Patterns traversing symlinks outside the snapshot are refused. Ordinary final
symlinks are archived as links, not recursively followed: explicitly declare any
external data you want protected, using an appropriate snapshot source.

## Coverage

The five existing host/tag identities remain `angel` / `angel-GROUP`:

- `state`: projects/art; GIMP; Krita resources/preferences (including SQLite/WAL);
  BeeRef INI; Ardour 8/9; Carla/falkTX; Fcitx; Zathura SQLite/WAL; Millennium CSS
  and sanitized preferences; selected Minecraft instance metadata, saves, config,
  scripts, mods and packs. Hidden instances, launcher accounts, libraries, logs
  and downloaded game binaries are excluded by the path selection.
- `legcord`: full profile, except regenerable caches/diagnostics/runtime locks.
- `anki`: collections, media, add-ons/settings and profile configuration, with WAL.
- `firefox`: full current/legacy profile roots including passwords, cookies,
  history, extensions/state and website storage. Ordinary caches/crashes/locks
  are excluded; IndexedDB is not silently removed in this migration.
- `terraria`: native Terraria/tModLoader data and native Steam userdata/Proton
  saves for app IDs 105600 and 1281930. Flatpak Steam was removed and its legacy
  save locations are empty; the separate Flatpak subvolume is **not** part of
  `/persist`. Reintroducing Flatpak saves requires a separate snapshot source.

Full profiles intentionally contain authentication/private history. Dedicated
credential stores, OS keyrings, recovery keys, mail/contacts/calendars, private
AI history and Taskwarrior remain outside selected paths. Mozc learned state is
still not selected. Device-bound or expired sessions may require reauthentication.

The only application-specific transformation is a jq whitelist for Millennium's
preferences, excluding its network/proxy-credentials block. Its sanitized output
is stored as `millennium.json` in the state's snapshot file tree; merge it back
rather than replacing a newer full configuration. There are no app-closed checks,
profile-copy loops, custom restic dispatch, or SQLite export routines.

## Scheduling, credentials and maintenance

Native system timers run daily at 03:00/10/20/30/40, with jitter and persistent
catch-up. Failures retry after 30 minutes; ordinary laptop sleep is not inhibited.
A standard flock wrapper (`locked-restic.nix`) queues commands sharing this
repository so an exclusive check cannot collide with another group's upload. Successful jobs are checked,
then record a heartbeat; failed attempts record a persistent failure marker.

Existing SOPS credentials are decrypted via the existing user service, without
hardware signing or new enrollment. Backup-only credentials are cached atomically
in root-private `/run/angel-backup-credentials` (0700, files 0600), survive user
logout during uploads, and disappear at reboot. Secrets never enter the Nix
store, command arguments or logs. Native root-readable wrappers are named
`restic-angel-state`, `restic-angel-firefox`, etc.; manual access requires root.
The old `angel-state-backup --group ...` interface is retired.

The existing Nextcloud `Backups/angel-state` repository and encryption password
are unchanged. Automatic initialization is disabled. Source paths in **new**
snapshots change to `/run/restic-backups-angel-GROUP/view/home/bloodwolfe/...`;
content deduplication and old snapshots remain usable. Restore with a native
restic wrapper into a fresh private directory; native restic can merge into an
existing destination, so do not point it at the live home accidentally.

Weekly maintenance requires a checked success for each new group, no persistent
failure markers and no active/starting/stopping group jobs. These gates are
rechecked **inside** the shared lock before every maintenance command, including
pruning, not before waiting for it. Credential setup failures mark all groups
failed until checked backups succeed. Busy/failed maintenance retries hourly.
It checks, performs native grouped
retention/prune (7 daily / 4 weekly / 6 monthly, known tags only), and checks again.
A failed/partial backup blocks pruning across reboots until a checked retry
succeeds. The native module performs ordinary stale-lock cleanup, not forced
removal of active repository locks. No repository initialization or data migration
is involved. Data reads during restore drills remain necessary; metadata checks
are not full payload verification.

Failures and hourly stale checks notify the existing SwayNC desktop session.
Warnings start at 48 hours, critical at seven days/missing history, with failed
jobs reported explicitly. These are **local notifications**, not independent
monitoring of an offline laptop. Journals remain available without a desktop.

## Deployment and rollback

Use the reviewed `/tmp/deploy-angel-snapshot-backups` helper. It shows the exact
diff and asks for review. A privileged filesystem-only preflight creates/validates
local snapshots using the already tested closure (no remote backup or activation).
It then requires human hardware-backed signing/push, builds the exact canonical
revision, asks before activation, stops the old user timers and waits on their
existing lock before switching. It does not close applications, initialize repositories,
prune boot generations, delete `/sync` subvolume 258 or remove Sober's subvolume.
New jobs are started after the switch; first-run checks/heartbeats establish
maintenance eligibility. Never run old and new backup implementations together.

Older `/tmp` commissioning scripts use the retired CLI; do not reuse them
unchanged. Old snapshot data and the old user's persisted backup state remain
available for recovery/old-generation rollback. Stop new system backup jobs
before rolling back to a generation with the old user jobs.

## Verification

`test-vm.nix` runs a real Btrfs filesystem, Btrbk and native restic services in an
isolated NixOS VM, using synthetic data and a local encrypted repository. It
checks live SQLite/WAL recovery, writes after the snapshot not appearing in the
restore, read-only enforcement, per-group local retention, and refusal of nested
subvolumes (including ancestors of otherwise missing paths), mount overlays and
escaping source symlinks. It also changes a failure gate while maintenance is
waiting on the repository lock, verifies no pruning, then permits real pruning
without deleting an unrelated group's snapshots. No VM test reads real
credentials or accesses Nextcloud. Validate Angel, Angelstuck and Navi evaluation
and build Angel before signing/deployment. Live post-deployment backup/restore
verification remains a separate operational check.
