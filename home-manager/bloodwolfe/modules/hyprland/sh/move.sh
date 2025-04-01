key=$1
case $key in
  h)
    hyprctl dispatch moveactive "-$HL_MOVE" 0
    ;;
  j)
    hyprctl dispatch moveactive 0 "$HL_MOVE"
    ;;
  k)
    hyprctl dispatch moveactive 0 "-$HL_MOVE"
    ;;
  l)
    hyprctl dispatch moveactive "$HL_MOVE" 0
    ;;
  *)
    exit 1
    ;;
esac
