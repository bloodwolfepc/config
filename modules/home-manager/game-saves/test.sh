#!/usr/bin/env bash
set -euo pipefail
export HOME="$TMPDIR/home"
export GAME_SAVES_CONFIG="$TMPDIR/policy"
export GAME_SAVES_STATE="$TMPDIR/state"
export GAME_SAVES_BACKUPS="$TMPDIR/backups"
export GAME_SAVES_INBOX="$TMPDIR/inbox"
export GAME_SAVES_STATUS="$TMPDIR/status"
mkdir -p "$HOME" "$GAME_SAVES_CONFIG" "$GAME_SAVES_STATE/native" "$TMPDIR/bin"
printf 'first\n' > "$HOME/first.sav"
printf 'second\n' > "$HOME/second.sav"
cat > "$GAME_SAVES_STATE/native/manifest.yaml" <<'YAML'
Local Fixture:
  files:
    <home>/first.sav: {}
Cloud Fixture:
  files:
    <home>/second.sav: {}
  cloud:
    steam: true
YAML
cat > "$GAME_SAVES_CONFIG/config.yaml" <<'YAML'
manifest:
  enable: true
backup:
  filter:
    cloud:
      exclude: true
      steam: true
cloud:
  synchronize: false
release:
  check: false
YAML
# Keep the real native CLI offline; its global flag precedes the subcommand.
native=$(command -v ludusavi)
printf '#!/bin/sh\nexec "%s" --no-manifest-update "$@"\n' "$native" > "$TMPDIR/bin/ludusavi"
chmod +x "$TMPDIR/bin/ludusavi"
export PATH="$TMPDIR/bin:$PATH"
chmod 0444 "$GAME_SAVES_CONFIG/config.yaml"
before=$(sha256sum "$GAME_SAVES_CONFIG/config.yaml")
bash "$RUNNER" backup --preview --api > preview.json
jq -e '.games | keys == ["Local Fixture"]' preview.json
bash "$RUNNER" backup --force --api > first.json
jq -e '.games | keys == ["Local Fixture"]' first.json
[[ "$(sha256sum "$GAME_SAVES_CONFIG/config.yaml")" == "$before" ]]
# Native policy edits, not a separate allowlist, control the next invocation.
sed -i 's/exclude: true/exclude: false/' "$GAME_SAVES_CONFIG/config.yaml"
bash "$RUNNER" backup --force --api > both.json
jq -e '.games | keys == ["Cloud Fixture", "Local Fixture"]' both.json
printf 'changed\n' > "$HOME/first.sav"
bash "$RUNNER" restore --force --api > restored.json
grep -qx first "$HOME/first.sav"
export GAME_SAVES_REFRESH="$TMPDIR/refresh"
printf '#!/bin/sh\ntouch "%s"\n' "$TMPDIR/refreshed" > "$GAME_SAVES_REFRESH"
chmod +x "$GAME_SAVES_REFRESH"
bash "$RUNNER" wrap --name 'Local Fixture' -- bash -c 'printf postexit > "$HOME/first.sav"'
test -f "$TMPDIR/refreshed"
printf changed > "$HOME/first.sav"
bash "$RUNNER" restore --force 'Local Fixture' --api > wrap-restore.json
grep -qx postexit "$HOME/first.sav"
printf '#!/bin/sh\nexit 1\n' > "$GAME_SAVES_REFRESH"
if bash "$RUNNER" wrap --name 'Local Fixture' -- touch "$TMPDIR/should-not-launch"; then exit 1; fi
test ! -e "$TMPDIR/should-not-launch"
GAME_SAVES_REFRESH='' bash "$RUNNER" wrap --name 'Local Fixture' -- touch "$TMPDIR/should-not-launch" && exit 1
test ! -e "$TMPDIR/should-not-launch"
printf '{}\n' > "$GAME_SAVES_STATE/import-pending.json"
printf '{"ok":true}\n' > "$GAME_SAVES_STATUS/angel.json"
if bash "$RUNNER" receive; then exit 1; fi
jq -e '.ok == false and (.error | contains("Interrupted import"))' "$GAME_SAVES_STATUS/angel.json"
rm "$GAME_SAVES_STATE/import-pending.json"
exec 8>"$GAME_SAVES_STATE/lock"
flock 8
if bash "$RUNNER" backup --force; then echo 'Concurrent operation unexpectedly succeeded' >&2; exit 1; fi
