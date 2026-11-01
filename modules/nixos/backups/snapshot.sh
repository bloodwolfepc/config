# Invoked by the native restic service before it reads any source files.
# Arguments: btrbk config, source mount, snapshot directory, view, snapshot name,
# then pairs of literal prefixes and files-from patterns to validate.
config=$1 source=$2 snapshots=$3 view=$4 name=$5
shift 5
[[ "$(findmnt -n -M "$source" -o FSTYPE)" == btrfs ]] || { echo 'Backup source is not the expected Btrfs mount' >&2; exit 1; }
[[ ! -e "$view" && ! -L "$view" ]] || { echo 'Snapshot view already exists' >&2; exit 1; }
# Reserve headroom for copy-on-write activity; do not delete data to manufacture space.
available=$(df -B1 --output=avail "$source" | tail -n1)
(( available >= 10737418240 )) || { echo 'Less than 10 GiB free: snapshot backup refused' >&2; exit 1; }
mkdir -p "$snapshots"
[[ "$(realpath "$snapshots")" == "$snapshots" ]] || { echo 'Symlinked snapshot directory refused' >&2; exit 1; }
find "$snapshots" -mindepth 1 -maxdepth 1 -type d -name "$name.*" -printf '%f\n' | sort >"${view}.before"
btrbk -c "$config" run
find "$snapshots" -mindepth 1 -maxdepth 1 -type d -name "$name.*" -printf '%f\n' | sort >"${view}.after"
mapfile -t created < <(comm -13 "${view}.before" "${view}.after")
[[ ${#created[@]} == 1 ]] || { echo 'Btrbk did not create exactly one fresh snapshot' >&2; exit 1; }
snapshot="$snapshots/${created[0]}"
[[ ! -L "$snapshot" && "$(btrfs property get -ts "$snapshot" ro)" == ro=true ]] || { echo 'Snapshot is not read-only' >&2; exit 1; }
# Mount overlays are not captured by a parent snapshot. Nested Btrfs subvolumes
# become inode-2 stubs inside snapshots: reject them within selected path prefixes.
findmnt --json -R "$source" -o TARGET | jq -r '.. | objects | .target? // empty' >"${view}.mounts"
declare -A checked=()
shopt -s dotglob nullglob
while (( $# )); do
  relative=$1 pattern=$2
  shift 2
  if [[ -z "${checked[$relative]+present}" ]]; then
  selected=$(realpath -ms "$source/$relative")
  scope=${selected%/}
  while IFS= read -r target; do
    if [[ "$target" != "$source" && ( "$target" == "$selected" || "$target" == "$scope/"* || "$selected" == "${target%/}/"* ) ]]; then
      echo 'A selected backup path crosses a mount; declare a separate snapshot source' >&2
      exit 1
    fi
  done <"${view}.mounts"
  path="$snapshot/$relative"
  ancestor=$path
  while [[ ! -e "$ancestor" && ! -L "$ancestor" ]]; do ancestor=$(dirname "$ancestor"); done
  [[ "$(stat -c %i "$ancestor")" != 2 ]] || { echo 'A selected path has a nested subvolume ancestor; backup refused' >&2; exit 1; }
  if [[ -e "$path" && ! -L "$path" ]]; then
    stub=$(find "$path" -xdev -type d -inum 2 -print -quit)
    [[ -z "$stub" ]] || { echo 'A selected path contains a nested subvolume; backup refused' >&2; exit 1; }
  fi
  checked[$relative]=1
  fi
  savedIFS=$IFS
  IFS=
  # shellcheck disable=SC2206 # Intentional filename globbing, with word splitting disabled.
  matches=( "$snapshot"/$pattern )
  IFS=$savedIFS
  for match in "${matches[@]}"; do
    parent=$(realpath -m "$(dirname "$match")")
    [[ "$parent" == "$snapshot" || "$parent" == "$snapshot/"* ]] || { echo 'A source pattern traverses a symlink outside the snapshot' >&2; exit 1; }
  done
done
ln -s "$snapshot" "$view"
printf 'Backing up read-only snapshot: %s\nApplications may remain open.\n' "$snapshot"
