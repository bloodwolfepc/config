key=$1
floating=$(hyprctl clients -j | jq -r '.[] | select(.focusHistoryID == 0) | .floating')
counter_move_value=$((HL_RESIZE / 2))        
case $key in
  h)
    hyprctl dispatch resizeactive "-$HL_RESIZE" 0
    [ "$floating" == "true" ] && hyprctl dispatch moveactive "$counter_move_value" 0
    ;;
  j)
    hyprctl dispatch resizeactive 0 "$HL_RESIZE"
    [ "$floating" == "true" ] && hyprctl dispatch moveactive 0 "-$counter_move_value"
    ;;
  k)
    hyprctl dispatch resizeactive 0 "-$HL_RESIZE"
    [ "$floating" == "true" ] && hyprctl dispatch moveactive 0 "$counter_move_value"
    ;;
  l)
    hyprctl dispatch resizeactive "$HL_RESIZE" 0
    [ "$floating" == "true" ] && hyprctl dispatch moveactive "-$counter_move_value" 0
    ;;
  n)
    hyprctl dispatch resizeactive "$HL_RESIZE" "$HL_RESIZE"
    ;;
  p)
    hyprctl dispatch resizeactive "-$HL_RESIZE" "-$HL_RESIZE"
    ;;
  *)
    exit 1
    ;;
esac
