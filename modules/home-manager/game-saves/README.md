# Native game saves with an Android-only routine handoff

Ludusavi owns discovery, backup, retention and the actual filesystem restore.
The existing Nextcloud daemon owns transport. A small adapter translates explicitly
submitted phone ZIPs into disposable native Ludusavi backups/redirects; it does not
implement WebDAV, a path database, a file-replacement engine or save merging.

## Native policy and overlays

Edit `home-manager/bloodwolfe/modules/game-saves/config.yaml`. Angel reads this
checkout on each invocation; Angelstuck uses its store-backed generation. The
launcher copies policy into private runtime state because native commands rewrite
configuration. Manifest/cache data stays there and Ludusavi updates it itself.

Native `backup.filter.cloud` excludes games *known by manifest metadata* to support
storefront cloud saves; it does not inspect account settings or prove unknown games
lack cloud support. There is no per-game allowlist or installed-game name in code.

The exposed `customGames: []` uses native entries for missing games and extensions:

```yaml
customGames:
  - name: An Unlisted Game
    integration: extend
    files:
      - <home>/.local/share/example-game/saves
```

Unknown titles are added; `extend` augments an existing exact title, `override`
replaces it. Native defaults to override. Native secondary manifests can also be
configured with absolute/home-relative paths. No real overlay has been enabled.

## One-time setup

1. Promote/deploy on Angel, initialize the native manifest and inspect backup preview.
2. For each Steam game used for handoffs, set its launch options to
   `game-saves wrap --infer steam -- %command%` (no game-specific name/path needed).
   Existing custom launch options must be deliberately composed, not overwritten.
   The normal launch must stay attached until the entire game exits; don't force-kill
   the wrapper or use a launcher that returns before the game closes.
3. Android Round Sync: download native backup data from `/game-saves/ludusavi`;
   upload return archives to `/game-saves/inbox`; download `/game-saves/status`.
   Keep separate directions/tasks and wait for task completion. No destructive mirrors.

The wrapped launch performs a blocking inbox refresh through the existing Nextcloud
client, applies completed submissions, then uses native `wrap --no-restore
--force-backup` to back up after exit. An unavailable/failed refresh blocks the
launch rather than claiming freshness. There are no routine Angel copy/confirm
steps once launch integration is configured. Other launchers need their native
wrap integration; an unwrapped game is not covered by this lifecycle guarantee.

## Routine actions — on Android only

Angel -> phone: save/exit normally on Angel. Wait for upload, download the game's
native **simple-format** backup and import its actual raw save files through
GameNative. The backup's mapping.yaml/drive directory is not itself a GameNative
import format. Select the intended native version, not an arbitrary stale slot.

Phone -> Angel: save and fully exit GameNative, export the selected save files,
choose canonical files (not ambiguous numbered duplicates), create one completed
ZIP, name it `<exact native title>--<unique handoff ID>.zip`, and upload it to the
inbox. A fresh timestamp/ID in the filename distinguishes a deliberate new handoff
from retrying an old file. Never modify a processed handoff ID or queue competing
unprocessed ZIPs for the same game. ZIP folder paths aren't used as destination
paths; only unique basenames already discovered by native Ludusavi are accepted.

**Submitting this archive explicitly means PHONE WINS.** It is not shared-ancestry
inference. Before overwrite, the adapter makes, verifies and locks a native backup
of PC progress. That checkpoint is outside normal native retention until manually
unlocked. This preserves divergent PC progress without guessing how to merge it.

The background receiver retries every two minutes while idle; the pre-launch check
also waits for completed transport and processes submissions before the game runs.
Duplicate delivery of one immutable event is ignored. A *new* event with identical
bytes is a deliberate new request and can replace subsequent PC progress.

Android can inspect `/game-saves/status/angel.json` for timestamped results/errors.
This is a synced status file, not push notification; its delivery also needs working
transport. No new notification credentials or service are introduced.

## Limits and recovery

- File-based games with existing, uniquely named native destinations only. Unknown
  files/new slots, ambiguous multi-root basenames, registry data, symlinks, traversal,
  ZIP bombs and numbered-copy guessing are refused. No format conversion is assumed.
- ZIP limit: 256 MiB compressed / 512 MiB expanded / 10,000 files. No direct extraction
  into save directories: actual writes are performed by native Ludusavi restore.
- Wrapped sessions hold the shared lock. Steam process detection additionally defers
  imports; unknown unreadable processes fail closed (known protected session daemons
  are excluded). Non-Steam sessions must also use the wrapper and stay attached.
- Native multi-file restore is not atomic. A failed/interrupted import leaves
  `~/.local/state/game-saves/import-pending.json`; native producers and launches stop.
  The marker identifies the locked native backup for recovery. Inspect that backup
  with native restore/preview and verify recovered progress before clearing the marker.
  Exceptional repair can be administered from Android SSH; don't blindly erase it.
- Native 0.31 uses second-resolution backup IDs; adjacent controlled backups are
  separated to avoid ID collisions. Don't run another writer against this backup tree.

Native output `~/.local/share/nextcloud-sync/game-saves` is synchronized to
`/game-saves/ludusavi` and selected by existing encrypted restic state backup.
Default native retention is 7 full/0 differential plus locked handoff checkpoints.
Nextcloud is not atomic multi-file publication or end-to-end encryption. Wait for
complete sync before using native backups on Android; restic is separate recovery.
Original raw cloud exports and old private history are not migrated/deleted here.

Synthetic native roundtrips, recovery, ZIP validation, replay, process/freshness and
launch lifecycle are tested. Real changed-progress loading, Android archive workflow
and network/offline acceptance remain operator tests, not inferred from a build.
