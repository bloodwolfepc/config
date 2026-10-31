# Angel state backups

`angel-state-backup` uses restic over rclone's Nextcloud WebDAV backend, reusing
SOPS Nextcloud credentials plus `restic-angel-nextcloud-password`. The repository
is `Backups/angel-state`; it is separate from the folder-sync daemon. Credentials
are passed through environment/password files, never command arguments or logs.

## Before activation

1. Enroll `restic-angel-nextcloud-password` in the secrets repository's
   `sops/users/bloodwolfe/angel.yaml`. The human-run helper
   `/tmp/enroll-angel-backup-secret` takes a new private recovery-file path outside
   repositories. It prepares unsigned topic work, without committing, pushing,
   signing or rebuilding.
2. Preserve the password independently, offline or in a recoverable password
   manager. A local recovery file alone does not survive losing Angel. Treat this
   password as access to the backed-up accounts, not just artwork. Never rotate
   the SOPS password without adding its replacement to the restic repository.
3. Review/promote the secrets change through the Secure workflow, update this
   flake's pinned secrets input, then rebuild Angel. The pin now includes the
   enrolled password; activation must still use the reviewed, promoted config.
4. Run `/tmp/initialize-angel-backups` in an existing terminal. It asks for
   confirmation of an independent recovery copy and initializes the encrypted
   repository. Initialization is explicit and happens only once for all groups.
5. Allow backups with the relevant apps closed, then test restoration of each
   recovery group before relying on it. No cloud backup/restore has been tested
   before enrollment and initialization.

## Independent recovery groups

Each group has its own success timestamp, snapshot tag and retention. An open
Firefox session does not defer artwork or another application's backups.

- **`state`** (the default): artwork under `~/projects/art/{gimp,krita,beeref}`;
  GIMP, Krita resources/preferences, BeeRef INI, Ardour 8/9, Carla/falkTX and Fcitx5
  settings; selected Millennium preferences/CSS; Zathura bookmarks; and selected
  Minecraft instance data. Save future artwork and supporting assets under the
  project directories: the module does not rewrite application last-save paths.
  - Krita's resource database and Zathura bookmarks use SQLite's online backup
    API with integrity checks, including committed WAL data.
  - Millennium excludes the network/proxy-credentials block and reinstallable
    plugins/themes. Restored JSON is a sanitized subset to merge, not blindly
    replace a newer full configuration.
  - Minecraft includes instance metadata, worlds, config, scripts/KubeJS,
    screenshots, mods and resource/shader/data packs. Hidden/trash instances,
    accounts.json, game binaries, logs, libraries and launcher caches are omitted.
    All per-instance mods/packs are included because local edits cannot be
    reliably inferred. Symlinked Minecraft roots are refused.
- **`legcord`**: full `~/.config/legcord` profile, including themes/plugins, local
  storage, settings, cookies and login state. Known caches, diagnostics,
  Chromium temporary files and singleton locks are omitted.
- **`anki`**: full `~/.local/share/Anki2` plus `~/.config/Anki{,2}` if present:
  collections, media, add-ons and their settings, preferences and built-in backups.
  Databases and WAL files are copied together with Anki closed. Linked profiles
  or media directories require explicit inclusion instead of silent omission.
- **`firefox`**: full `~/.config/mozilla/firefox` and `~/.mozilla/firefox` if present,
  including saved logins/key databases, cookies, history, extensions and their
  data, preferences and session recovery. Known caches, crash diagnostics and
  runtime locks are omitted. Registered profiles outside their backed-up root
  cause an error so they can be explicitly included.
- **`terraria`**: native `~/.local/share/Terraria`, including players, worlds,
  configuration and tModLoader data; the equivalent Steam Flatpak data directory;
  Steam-cloud `userdata/*/{105600,1281930}/remote`; and standard Proton
  `Documents/My Games/Terraria` save directories for those app IDs. Steam roots
  checked are `~/.local/share/{Steam,steamgames}` and the Steam Flatpak data root.
  Custom libraries elsewhere require explicit additions. Reinstallable game
  binaries and downloaded Steam Workshop content are not included.

**Full-profile groups deliberately include passwords, tokens and private history
where present.** Keep decrypted restores private. Device-bound or expired sessions
may still require signing in again; OS keyrings are not newly added to this scope.

Taskwarrior remains untouched and excluded. Dedicated credential stores, mail,
contacts/calendars, VM/container state, private AI history and recovery keys also
remain outside this change. WirePlumber and Zoxide are excluded. Fcitx settings
are covered, but Mozc's separate learned state in `~/.config/mozc` still needs a
persistence/export decision.

## Schedule and safety

Timers check hourly at staggered minutes with two minutes of jitter; a group's
successful backup suppresses further scheduled runs for 24 hours. Each relevant
application must be closed before and throughout its export. Terraria also waits
for Steam and dotnet to exit, avoiding Steam-cloud save rewrites. An unrelated
Java process defers `state`, and unrelated dotnet activity defers `terraria`.
Zathura may stay open because its database uses the SQLite backup API.

A common local lock serializes repository operations; a collision exits 75 and
retries on a later timer tick, without marking success. Private staging lives in
`~/.local/state/angel-state-backup/export` for `state`, and
`profiles/GROUP/export` below that state directory for the other groups. Copies
use reflinks when possible. Allow enough disk space if copying is necessary.
This is not an atomic filesystem snapshot: do not launch apps during export.
Normal attempts remove staging afterward; interrupted attempts are cleaned up on
retry. Symlinks are preserved rather than recursively dereferenced; linked
external assets still require their own backup. A missing application's sources
fail visibly rather than recording an empty successful profile backup.

A successful snapshot is checked before retention, then pruned to 7 daily,
4 weekly and 6 monthly snapshots for host `angel` and tag `angel-GROUP`, followed
by another metadata check. Partial backups or failed pre-retention checks never
prune. Failed retention/checks do not mark success. Metadata checks do not read
every data blob: periodically perform real restore tests.

## Operator interface

```text
angel-state-backup init
angel-state-backup backup
angel-state-backup --group firefox backup
angel-state-backup --group firefox snapshots
angel-state-backup check
angel-state-backup --group firefox restore latest /some/new/restore-directory
```

`backup` bypasses only the 24-hour suppression, not the application gate. Choose
the same group for listing/restoring its snapshots; omitted `--group` means
`state`. Restore refuses an existing destination and produces an inspectable
`home/` tree. Copy selected files back with the app closed, retaining an old copy
first. Restore compatible application versions; account/session portability is
not guaranteed. User journal units are `angel-state-backup.service` for `state`
and `angel-state-backup-GROUP.service` for the other groups, with matching timers.

## Legacy sync retirement

Angel and Angelstuck no longer declare `/sync`; Navi's independent use is unchanged.
After the reviewed configuration is active, the human-run `/tmp/retire-angel-sync`
helper unmounts the old mount and clears only the three audited Syncthing marker
files plus empty directories. It retains empty Btrfs subvolume 258 so older
rollback generations can still mount it. It never removes the Flatpak subvolume
used by Sober. The helper refuses to run while the active fstab still declares
`/sync`; enrollment and pinning the backup secret must precede activation.

## Tests

Run `python3 -B -m unittest discover -s home-manager/bloodwolfe/angel/backups -v`
with Python, coreutils and restic from the flake environment. Tests use temporary
local repositories only: encrypted backup/restore of all five groups, independent
retention and schedules, authentication/media preservation, cache exclusions,
SQLite WAL export, external-profile safeguards and failed-backup retention.
