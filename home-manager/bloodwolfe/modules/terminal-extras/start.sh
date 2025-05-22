#!/usr/bin/env bash
set -exo pipefail
icon_file="$FLAKE/assets/crosshairs/hello_kitty_crosshiar_001.png"
notify-send --icon="$icon_file" "track-time start"
canberra-gtk-play --volume="-10" --id=power-plug


# current_timer=$(cat "$HOME/.pomodoro/current")
# duration=$(echo "$current_timer" | cut -f2 -d'=')
# sleep "${duration}m"
# current_timer_re=$(cat "$HOME/.pomodoro/current")
# if [[ "$current_timer" = "$current_timer_re" ]]; then
#   notify-send --icon="$icon_file" "❌❌❌❌❌"
#   canberra-gtk-play --volume="-15" --id=complete
# fi 
