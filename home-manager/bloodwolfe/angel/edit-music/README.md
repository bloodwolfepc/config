# Angel edit-music client

Implements version 1 of `srv/doc/edit-music-revision.md` through the host's
`srv-music-workbench` interface. This checkout does not deploy the server.

## Migration gate

The live publisher still auto-shares manual music. **Migrate it before enabling
private acquisition/import:** stop it, recreate only its slskd container with the
approved-only read-only publication share, verify no grandfathered personal files,
then recreate only the pinned music-editor. Preserve the VPN containers and editor
application state. Follow the server's complete deployment/acceptance protocol.
Do not run the new private workflow against the old publisher.

Every invocation verifies host backend version, identity and advertised commands.
Normal shell, acquisition, extraction, import, review, albums, publication,
resumption and cache cleanup additionally require successful backend `check`.
That server check verifies the running image identity and publisher migration,
not just a matching protocol number. Missing/incompatible/stale/unsafe backends
fail with migration instructions; there is no old-workflow or local-fetch fallback.

Status, withdrawal and purge intentionally need only host protocol compatibility:
the documented backend supports those recovery operations without an editor.
Resume can expose an already-approved publication, so this client conservatively
requires current editor/migration readiness for it too. It never calls `prepare`
or recreates containers. Server provisioning belongs to the operator.

## Interface

No arguments retains the normal Starship upload followed by interactive login
zsh. A valid `STARSHIP_CONFIG` overrides `~/.config/starship.toml`; an unset,
empty or missing override falls back to that Home Manager file. Both SSH upload and
interactive shell occur only after readiness. Interactive operations authenticate
on a data-free readiness connection (normal SSH terminal prompts remain possible),
then reuse its private short-lived control socket. Payload/theme transfers still
use BatchMode and never share stdin with prompts; importer/publication get separate
SSH TTY sessions. The socket/master is closed afterward. Other operations need no theme.

- `--dl HTTPS_URL [--name BASENAME]`: direct file acquisition inside the editor's
  VPN, never on Angel. Provider web pages need the native provider CLI in zsh.
- `--dl LOCAL_PATH`: preserve the original, resolve its parent on Angel and spool
  a private validated tar rooted at its basename. Send it to `receive` with a fresh
  UUID job name in a noninteractive BatchMode SSH connection. No leading `./`,
  symlinks, special files, traversal or unsupported control characters; regular
  hardlinked files become independent regular tar entries. Descriptor-relative
  traversal refuses link swaps. The backend enforces its own limits too.
- `--extract /workspace/staging/ARCHIVE`: use backend safe ZIP/tar extraction inside
  the VPN editor. Never extract downloads on Angel.
- `--import /workspace/staging/RELEASE`: **separate SSH TTY** for the native Beets
  importer and ambiguity prompts. Transfers never share stdin with prompts.
- `--albums`, `--review BEETS_ALBUM_ID`, `--status`: pretty JSON, with provenance
  URLs/private fields redacted. Readiness blockers and warnings remain visible;
  successful report retrieval is not approval or permission to redistribute.
- `--publish BEETS_ALBUM_ID`: collect a hidden private permission/license basis
  for music **and artwork**, and deliberately public attribution. The backend
  prints its current review and requires its own typed confirmation over SSH TTY.
  Optional `--basis`, `--attribution`, `--replace PUBLICATION_ID` are passed as
  separate safely quoted arguments. Blank permission/attribution is refused.
- `--publish BEETS_ALBUM_ID --basis TEXT --attribution TEXT --yes`: deliberate
  noninteractive approval of **one** album, never a future automatic policy.
  `--yes` is rejected outside `--publish` and requires both texts explicitly.
- `--unpublish PUBLICATION_ID`: withdraw exactly that publication, not a broad
  Beets query. Existing peer downloads/transfers cannot be recalled.
- Advanced: `--resume PUBLICATION_ID`, `--purge PUBLICATION_ID`, `--cache-clean`.
  Purge relies on the server's withdrawn/unchanged-managed-snapshot checks and
  never deletes the Beets original. After publication failure, inspect status and
  resume the journalled ID, rather than blindly repeating publication.
- `--check`: verify and show compatible running editor/migration information.

Acquisition, upload, extraction and import **never publish automatically** and
are deliberately separate invocations. Use the exact absolute path printed by
the backend; do not guess a job name. A local receive returns a content directory
containing the original basename; a received archive is inside that directory.
Native tools and ad-hoc pinned Nix tools remain available in the normal shell.

## Privacy and limits

The client writes no persistent operation logs. Noninteractive SSH stderr is
suppressed because process/network errors can contain signed URLs or credentials;
errors instead give safe status/migration guidance. Remote argv is POSIX-quoted,
not interpolated as shell fragments. HTTP URLs and embedded URL user/passwords
are rejected. JSON display redacts URLs and private basis/password/token fields.
Interactive native shell/importer/backend confirmation output remains native;
there is no terminal recorder.

The documented interface necessarily passes URLs and permission text through SSH
process arguments/remote commands. This client cannot prevent external process
inspection, shell history from explicitly supplied CLI arguments, or server-side
command auditing; prefer the hidden basis prompt and avoid command recording.
No credentials/URLs are copied into diagnostics or persistent client logs.

Local tar validation happens **before** opening the receive connection, at a cost
of temporary local disk roughly equal to input size (up to 20 GiB / 10,000 entries).
It is packaging local input, not fetching/extracting remote content. Temporary
files are private/unlinked and closed on failure; originals are untouched.
Choose a suitably provisioned private `TMPDIR` for large albums. This is not a
filesystem snapshot of concurrently edited local files. Network interruption can
require inspecting staged jobs before retrying; no automatic import/publication
follows a failed transfer.

## Validation and remaining acceptance

`checks.<system>.edit-music` runs hermetic Python CLI tests against fake SSH,
including PTY shell/import/publication sessions, protocol/migration refusal,
quoted hostile/option-like arguments, relative colon filenames, private SSH
connection reuse, safe local tar payloads, limits, link/special-file
refusal, explicit approval, recovery without an editor, privacy and no-theme
backend operations. It never connects to a real server or invokes a downloader.
The package is a store-backed script and changes require a Home Manager rebuild.

Real backend/image/publisher migration, network/VPN failure behavior, remote
prompt behavior, Navidrome visibility, actual publication/withdrawal, independent
peer transfer and server/NAS backups remain server acceptance gates. Construction
tests are not evidence that the live migration or any redistribution succeeded.
