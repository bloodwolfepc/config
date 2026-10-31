# droid-obtainium-list

Installed through Angel's Home Manager profile (also inherited by angelstuck).
Reads Nextcloud directly using the existing SOPS username/app-password files;
it never changes cloud files or configures a local sync directory.

```text
droid-obtainium-list
droid-obtainium-list --import-from-url-format
droid-obtainium-list --export-latest ./obtainium-backup.json
droid-obtainium-list --help
```

Searches `/droid-sync/` and its subfolders, selecting the newest Obtainium JSON
export by server modification time. Unrelated JSON objects without an `apps`
list are ignored; malformed JSON or app entries cause an error rather than
silently falling back to an older backup. Current schema, legacy `apps` wrappers,
and bare app arrays are supported. Only apps whose `installedVersion` is not
null are listed; this is the state recorded in the backup, not a live phone query.

Default output is sorted by app name with aligned uppercase column headings.
Terminal headings are white and rows are `#A070A0`. Redirected/piped output and
`NO_COLOR` output have no ANSI escapes. Names are sanitized for terminal output.

URL-list mode emits unique source URLs only, one per line, suitable for Obtainium's
**Import from URL list**. It does not preserve source-specific settings such as
APK filters, credentials, or custom names; import the JSON for a full restore.

`--export-latest PATH` additionally saves the original complete JSON, including
uninstalled apps and any settings, unchanged. The parent directory must already
exist. Existing files and symlinks are never overwritten; the new file has mode
0600. **Exports can contain credentials and other private settings.**

The Python entry point also runs elsewhere with Python 3 and the paths to
credential files supplied as `DROID_OBTAINIUM_USERNAME_FILE` and
`DROID_OBTAINIUM_PASSWORD_FILE`. The installed wrapper supplies those paths.

Tests (from this directory):

```text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest -v
```
