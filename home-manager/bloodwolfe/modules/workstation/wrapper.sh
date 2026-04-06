#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: gimp-wrapper <output.png>"
  exit 1
fi

OUT="$1"
BASENAME="$(basename "$OUT" .png)"
WORKDIR="./.gimp"
XCF="$WORKDIR/$BASENAME.xcf"

mkdir -p "$WORKDIR"

if [[ ! -f "$XCF" ]]; then
  gimp-console \
    -i \
    --batch-interpreter=python-fu-eval \
    -b "import project_init; project_init.create_project('$XCF')" \
    -b "quit()"
fi

exec gimp "$XCF"
