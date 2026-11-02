#!/usr/bin/env bash
set -euo pipefail
umask 077

command=${1:---help}
if (( $# )); then shift; fi
case "$command" in
  --help|--version) exec ludusavi "$command" "$@" ;;
esac
install -d -m 0700 "$GAME_SAVES_STATE"
exec 9>"$GAME_SAVES_STATE/lock"
flock -n 9 || {
  if [[ "$command" == receive ]]; then exit 0; fi
  echo 'Another Ludusavi operation is running.' >&2; exit 1;
}
native="$GAME_SAVES_STATE/native"
install -d -m 0700 "$native"
# Native commands rewrite config; copy the policy, not the downloaded cache.
cp "$GAME_SAVES_CONFIG/config.yaml" "$native/config.yaml"
chmod 0600 "$native/config.yaml"
cd "$native"
if [[ -e "$GAME_SAVES_STATE/import-pending.json" && "$command" != restore && "$command" != backups && "$command" != receive && "$command" != wrap ]]; then
  echo 'Interrupted phone import; inspect import-pending.json and native restore before continuing.' >&2
  exit 1
fi
case "$command" in
  receive) exec python3 "$GAME_SAVES_RECEIVER" "$@" ;;
  wrap)
    [[ -n "${GAME_SAVES_REFRESH:-}" ]] || { echo 'No blocking transport refresh configured; launch refused.' >&2; exit 1; }
    "$GAME_SAVES_REFRESH"
    python3 "$GAME_SAVES_RECEIVER" --before-launch
    # Native 0.31 uses second-resolution backup IDs; separate adjacent snapshots.
    sleep 1.05
    exec ludusavi --config "$native" wrap --path "$GAME_SAVES_BACKUPS" --no-restore --force-backup "$@"
    ;;
  backup|restore|backups)
    if [[ "$command" == backup ]]; then sleep 1.05; fi
    exec ludusavi --config "$native" "$command" --path "$GAME_SAVES_BACKUPS" "$@"
    ;;
  *) exec ludusavi --config "$native" "$command" "$@" ;;
esac
