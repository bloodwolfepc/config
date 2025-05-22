#!/usr/bin/env bash
set -exo pipefail
icon_file="$FLAKE/assets/crosshairs/hello_kitty_crosshiar_001.png"
notify-send --icon="$icon_file" "track-time break"
