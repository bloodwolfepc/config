set -euo pipefail
tmp_img="$(mktemp --suffix=.png)"
trap 'rm -f "$tmp_img"' EXIT
grimblast save area "$tmp_img"
tesseract "$tmp_img" stdout -l eng+jpn 2>/dev/null | wl-copy
