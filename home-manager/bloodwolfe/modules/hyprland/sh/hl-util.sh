
HYPR_CONF_DIR="$XDG_CONFIG_HOME/hypr"
SNC_CONF_DIR="$XDG_CONFIG_HOME/swaync"
WB_CONF_DIR="$XDG_CONFIG_HOME/waybar"
RECOLOR_RECORDS_FILE="$HYPR_CONF_DIR/recolors"
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.focusHistoryID == 0) | .address')
FLOATING=$(hyprctl clients -j | jq -r '.[] | select(.focusHistoryID == 0) | .floating')

get_hex() {
  HEX=$(hyprpicker -a -f hex)
  RGB=$(magick xc:"$HEX" -format "%[fx:int(255*r)], %[fx:int(255*g)], %[fx:int(255*b)]\n" info:)
}

function swaync_recolor() {
  function recolor() {
    get_hex
    sed -i "s/@define-color base0D .*/@define-color base0D $HEX;/" "$SNC_CONF_DIR/style.css"
    swaync-client --reload-css
    notify_color
  }
  if [ "$1" == "tmp" ]; then
    cp "$SNC_CONF_DIR/style.css" "$SNC_CONF_DIR/prev-style.css"
    recolor
    sleep 5
    mv "$SNC_CONF_DIR/prev-style.css" "$SNC_CONF_DIR/style.css"
    swaync-client --reload-css
  elif [ "$1" == "reset" ]; then
    rm "$SNC_CONF_DIR/style.css"
    cp "$FLAKE/home-manager/bloodwolfe/modules/swaync/style.css" "$SNC_CONF_DIR"
    swaync-client --reload-css
  else
    recolor
  fi
}

function waybar_recolor() {
  function recolor() {
    get_hex
    if [ "$1" == "text" ]; then
      sed -i "s/@define-color base07txt .*/@define-color base07txt $HEX;/" "$WB_CONF_DIR/style.css"
    else
      sed -i "s/@define-color base07 .*/@define-color base07 $HEX;/" "$WB_CONF_DIR/style.css"
    fi
    notify_color
  }
  if [ "$1" == "tmp" ]; then
    cp "$WB_CONF_DIR/style.css" "$WB_CONF_DIR/prev-style.css"
    recolor
    sleep 5
    mv "$WB_CONF_DIR/prev-style.css" "$WB_CONF_DIR/style.css"
    swaync-client --reload-css
  elif [ "$1" == "reset" ]; then
    rm "$WB_CONF_DIR/style.css"
    cp "$FLAKE/home-manager/bloodwolfe/modules/waybar/style.css" "$WB_CONF_DIR"
    swaync-client --reload-css
  else
    recolor "$1"
  fi
}

function grimblast_setwallpaper() {
  grimblast save "$1" "$HYPR_CONF_DIR/wallpaper.png"
  if [ "$2" == "fit" ]; then
    swww img "$HYPR_CONF_DIR/wallpaper.png" --transition-step 255 --resize fit
  else
    swww img "$HYPR_CONF_DIR/wallpaper.png" --transition-step 255
  fi
  notify-send \
    --app-name=WALLPAPER \
    --icon="$HYPR_CONF_DIR/wallpaper.png" \
    ""
}

function grimblast_screenshot() {
  grimblast copysave "$1" "$XDG_SCREENSHOTS_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"
}

function notify_color() {
  magick -size 1x1 xc:"$HEX" "$HYPR_CONF_DIR/color.png"
  notify-send \
    --app-name=COLOR \
    --icon="$HYPR_CONF_DIR/color.png" \
    "HEX: $HEX RGB: $RGB"
}

function activewindow_recolor() {
  get_hex
  echo "$ADDRESS = $HEX" >> "$RECOLOR_RECORDS_FILE"
  if [ "$1" == "inactivebordercolor" ]; then
    hyprctl dispatch setprop "address:$ADDRESS" inactivebordercolor "rgb(${HEX#"#"})"
  else
    hyprctl dispatch setprop "address:$ADDRESS" activebordercolor "rgb(${HEX#"#"})"
  fi
  notify_color
}

function activewindow_flash() {
  FLASH_COLOR="$1"; FLASH_COLOR="${FLASH_COLOR:-#ffffff}"
  FLASH_AMMOUNT="$2"; FLASH_AMMOUNT="${FLASH_AMMOUNT:-1}"
  FLASH_SLEEP_TIME="$3"; FLASH_SLEEP_TIME="${FLASH_SLEEP_TIME:-1}"
  ACTIVE_COLOR="$(tac "$RECOLOR_RECORDS_FILE" | grep "^$ADDRESS" | awk -F ' = ' '{print $2}' | head -n 1)"
  ACTIVE_COLOR="${ACTIVE_COLOR:-#bbbbbb}"
  for ((i=0; i<FLASH_AMMOUNT; i++)); do
    hyprctl dispatch setprop "address:$ADDRESS" activebordercolor "rgb(${FLASH_COLOR#"#"})" >/dev/null 2>&1
    sleep "$FLASH_SLEEP_TIME"
    hyprctl dispatch setprop "address:$ADDRESS" activebordercolor "rgb(${ACTIVE_COLOR#"#"})" >/dev/null 2>&1
    sleep "$FLASH_SLEEP_TIME"
  done
}

function activewindow_resize() {
  COUNTER_MOVE_VALUE=$((HL_RESIZE / 2))
  case $1 in
    l)
      hyprctl dispatch resizeactive "-$((HL_RESIZE))" 0
      #[ "$FLOATING" == "true" ] && hyprctl dispatch moveactive "$COUNTER_MOVE_VALUE" 0
      ;;
    d)
      hyprctl dispatch resizeactive 0 "$((HL_RESIZE))"
      #[ "$FLOATING" == "true" ] && hyprctl dispatch moveactive 0 "-$COUNTER_MOVE_VALUE"
      ;;
    u)
      hyprctl dispatch resizeactive 0 "-$((HL_RESIZE))"
      #[ "$FLOATING" == "true" ] && hyprctl dispatch moveactive 0 "$COUNTER_MOVE_VALUE"
      ;;
    r)
      hyprctl dispatch resizeactive "$((HL_RESIZE))" 0
      #[ "$FLOATING" == "true" ] && hyprctl dispatch moveactive "-$COUNTER_MOVE_VALUE" 0
      ;;
    e)
      hyprctl dispatch resizeactive "$((HL_RESIZE))" "$((HL_RESIZE))"
      ;;
    c)
      hyprctl dispatch resizeactive "-$((HL_RESIZE))" "-$((HL_RESIZE))"
      ;;
    *)
      exit 1
      ;;
  esac
}

function activewindow_mv() {
  key=$1
  case $key in
    l)
      hyprctl dispatch moveactive "-$((HL_MOVE))" 0
      ;;
    d)
      hyprctl dispatch moveactive 0 "$((HL_MOVE))"
      ;;
    u)
      hyprctl dispatch moveactive 0 "-$((HL_MOVE))"
      ;;
    r)
      hyprctl dispatch moveactive "$((HL_MOVE))" 0
      ;;
    *)
      exit 1
      ;;
esac
}

function main() {
  if [ "$1" == "activewindow" ]; then
    if [ "$2" == "flash" ]; then
      activewindow_flash "$3" "$4" "$5"
    elif [ "$2" == "spazz" ]; then
      activewindow_flash "$3" "100" "0.05"
    elif [ "$2" == "pinkspazz" ]; then
      activewindow_flash "#ff00ff" "100" "0.05"
    elif [ "$2" == "recolor" ]; then
      activewindow_recolor "$3"
    elif [ "$2" == "resize" ]; then
      activewindow_resize "$3"
      activewindow_flash "#ff00ff" "4" "0.05"
    elif [ "$2" == "mv" ]; then
      activewindow_mv "$3"
      activewindow_flash
    fi
  elif [ "$1" == "swaync" ]; then
    if [ "$2" == "recolor" ]; then
      swaync_recolor "$3"
    fi
  elif [ "$1" == "waybar" ]; then
    if [ "$2" == "recolor" ]; then
      waybar_recolor "$3"
    fi
  elif [ "$1" == "grimblast" ]; then
    if [ "$2" == "setwallpaper" ]; then
      grimblast_setwallpaper "$3" "$4"
    elif [ "$2" == "screenshot" ]; then
      grimblast_screenshot "$3"
    fi
  elif [ "$1" == "reset" ]; then
    waybar_recolor reset
    swaync_recolor reset
    swww img "$FLAKE/assets/wallpapers/black.png" --transition-step 255
  fi
}
main "$1" "$2" "$3" "$4" "$5"
