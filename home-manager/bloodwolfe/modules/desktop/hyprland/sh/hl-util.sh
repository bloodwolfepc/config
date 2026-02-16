HYPR_CONF_DIR="$XDG_CONFIG_HOME/hypr"
SNC_CONF_DIR="$XDG_CONFIG_HOME/swaync"
WB_CONF_DIR="$XDG_CONFIG_HOME/waybar"
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.focusHistoryID == 0) | .address')
FLOATING=$(hyprctl clients -j | jq -r '.[] | select(.focusHistoryID == 0) | .floating')
HL_RESIZE=${HL_RESIZE:-100}
HL_MOVE=${HL_MOVE:-100}


# flash=(color="#ffffff, ammount=1, interval=1)
function activewindow_flash_efx() {
  FLASH_COLOR="$1"; FLASH_COLOR="${FLASH_COLOR:-#ffff00}"
  FLASH_AMMOUNT="$2"; FLASH_AMMOUNT="${FLASH_AMMOUNT:-1}"
  FLASH_SLEEP_TIME="$3"; FLASH_SLEEP_TIME="${FLASH_SLEEP_TIME:-1}"
  ACTIVE_COLOR="${ACTIVE_COLOR:-#ffffff}"
  for ((i=0; i<FLASH_AMMOUNT; i++)); do
    hyprctl dispatch setprop "address:$ADDRESS" active_border_color "rgb(${FLASH_COLOR#"#"})" >/dev/null 2>&1
    sleep "$FLASH_SLEEP_TIME"
    hyprctl dispatch setprop "address:$ADDRESS" active_border_color "rgb(${ACTIVE_COLOR#"#"})" >/dev/null 2>&1
    sleep "$FLASH_SLEEP_TIME"
  done
}

function color() {
  HEX=$(hyprpicker -a -f hex)
  RGB=$(magick xc:"$HEX" -format "%[fx:int(255*r)], %[fx:int(255*g)], %[fx:int(255*b)]\n" info:)
  magick -size 1x1 xc:"$HEX" "$HYPR_CONF_DIR/color.png"
  notify-send \
    --app-name=COLOR \
    --icon="$HYPR_CONF_DIR/color.png" \
    "HEX: $HEX RGB: $RGB"
}

function grimblast_screenshot_setwallpaper() {
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

function activewindow_resize() {
  case $1 in
    l)
      hyprctl dispatch resizeactive "-$((HL_RESIZE))" 0
      ;;
    d)
      hyprctl dispatch resizeactive 0 "$((HL_RESIZE))"
      ;;
    u)
      hyprctl dispatch resizeactive 0 "-$((HL_RESIZE))"
      ;;
    r)
      hyprctl dispatch resizeactive "$((HL_RESIZE))" 0
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
  if [ "$FLOATING" ]; then
    case $1 in
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
  else
    hyprctl dispatch moveactive "$1"
  fi
}

function rofi_menu() {
  case $1 in
    exec)
      rofi -show run
    ;;
    cliphist)
      cliphist list | rofi -dmenu | cliphist decode | wl-copy
    ;;
    calc)
      rofi -modi calc -show calc -no-show-match -no-sort
    ;;
    emoji)
      rofi -modi emoji -show emoji
    ;;
    rssmon|top)
      rofi -modi top -show top
    ;;
    clients)
      rofi -modi window -show window
    ;;
    games)
      rofi -modi games -show games
    ;;
    power)
      rofi -modi power-menu:rofi-power-menu -show power-menu
    ;;
    network-manager|nmcli)
      rofi-network-manager
    ;;
    bluetooth|bt)
      rofi-bluetooth
    ;;
    systemd)
      rofi-systemd
    ;;
    pass)
      rofi-pass
    ;;
    pulse-sink|audio-out)
      rofi-pulse-select sink
    ;;
    pulse-source|audio-in)
      rofi-pulse-select source
    ;;
    *)
      echo "invalid arguments for rofi: ${@:2}"
      exit 1
    ;;
esac
}

function activewindow() {
  case $1 in
    flash)
      activewindow_flash_efx "${@:2}"
      ;;
    mvfocus)
      hyprctl dispatch movefocus "${@:2}"
      activewindow_flash_efx "#ff00ff" "1" "1.5"
      ;;
    resize)
      activewindow_resize "${@:2}"
      activewindow_flash_efx "#ff00ff" "4" "0.07"
      ;;
    mv)
      hyprctl dispatch movewindow "${@:2}"
      activewindow_flash_efx "#000000" "4" "0.07"
      ;;
    swap)
      hyprctl dispatch swapwindow "${@:2}"
      activewindow_flash_efx "#00ffff" "4" "0.07"
      ;;
    *)
      echo "invalid arguments for activewindow ${@:2}"
      exit 1
      ;;
esac
}

function screenshot() {
  case $1 in
    copy)
      grimblast "$@"
      ;;
    save)
      grimblast "$@" "$XDG_SCREENSHOTS_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"
      ;;
    copysave)
      grimblast "$@" "$XDG_SCREENSHOTS_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"
      ;;
    setwallpaper)
      grimblast_screenshot_setwallpaper "${@:2}"
      ;;
    *)
      echo "invalid arguments for screenshot: ${@:2}"
      exit 1
      ;;
  esac
}


function main() {
  case $1 in
    activewindow|aw)
      activewindow "${@:2}"
      ;;
    screenshot|ss)
      screenshot "${@:2}"
      ;;
    menu|m)
      rofi_menu "${@:2}"
      ;;
    color)
      color
      ;;
    *)
      echo "invalid arguments for main"
      exit 1
      ;;
  esac
}

main "$@"
