HYPRLAND_DEVICE="asue120a:00-04f3:319b-touchpad"

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

enable_touchpad() {
  printf "true" > "$STATUS_FILE"
  notify-send -u normal "Enabling Touchpad"
  hyprctl keyword "device[$HYPRLAND_DEVICE]:enabled" true
}

disable_touchpad() {
  printf "false" > "$STATUS_FILE"
  notify-send -u normal "Disabling Touchpad"
  hyprctl keyword "device[$HYPRLAND_DEVICE]:enabled" false
}

if ! [ -f "$STATUS_FILE" ]; then
  disable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi


#HYPRLAND_DEVICE="pxic2642:00-04ca:00b1-touchpad"
#HYPRLAND_VARIABLE="device:$HYPRLAND_DEVICE:enabled"
#
#if [ -z "$XDG_RUNTIME_DIR" ]; then
#  export XDG_RUNTIME_DIR=/run/user/$(id -u)
#fi
#
## Check if device is currently enabled (1 = enabled, 0 = disabled)
#DEVICE="$(hyprctl getoption $HYPRLAND_VARIABLE | grep 'int: 1')"
#
#if [ -z "$DEVICE" ]; then
#	# if the device is disabled, then enable
#  	notify-send -u normal "Enabling Touchpad"
#	hyprctl keyword $HYPRLAND_VARIABLE true
#else
#	# if the device is enabled, then disable
#	notify-send -u normal "Disabling Touchpad"
#	hyprctl keyword $HYPRLAND_VARIABLE false
#fi
