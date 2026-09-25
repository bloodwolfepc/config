#https://gist.github.com/Dregu/aa748bebc7c3aeddd3ceb55c0f046c5d#file-hyprvol-L17
sleep 2
if [[ -z "$1" ]]; then
  echo "Control active window volume in Hyprland"
  echo "Usage: hyprvol 5%-|5%+|toggle"
  exit 0
fi

pidtree() {
  [ -n "$ZSH_VERSION"  ] && setopt shwordsplit
  declare -A CHILDS
  while read P PP;do
    CHILDS[$PP]+=" $P"
  done < <(ps -e -o pid= -o ppid=)
  walk() {
    echo $1
    for i in ${CHILDS[$1]};do
      walk $i
    done
  }
  for i in "$@";do
    walk $i
  done
}

setvol() {
  for ID in "$@"; do
    if [ "$CMD" == "toggle" ]; then
      wpctl set-mute $ID toggle&
    else
      wpctl set-volume -l 1.5 $ID "$CMD"&
    fi
  done
}

# gather data
CMD="$@"
ACTIVE=$(hyprctl -j activewindow)
DUMP=$(pw-dump|jq ".[]|select(.type == \"PipeWire:Interface:Node\" or .type == \"PipeWire:Interface:Client\")|{id:.id, client:.info.props[\"client.id\"], type:.type, name:.info.props[\"media.name\"], class:.info.props[\"media.class\"], pid:.info.props[\"application.process.id\"]}"|jq -s .)

# try to find media matching window title first, mainly for individual firefox tabs
TITLE=$(echo "$ACTIVE"|jq -r .title)
# strip browser name from window title, firefox usually passes the page title as media.name which is convenient
TITLE=${TITLE% —*}

QUERY=".[]|select(.type == \"PipeWire:Interface:Node\" and .name == \"$TITLE\").id"
IDS=$(echo "$DUMP"|jq -r "$QUERY")
if [ -n "$IDS" ]; then
  setvol $IDS
else
  # no media matching window title, fallback to all nodes matching pid and its children
  PIDS=$(pidtree $(echo "$ACTIVE"|jq -r .pid))
  for PID in $PIDS; do
    QUERY=".[]|select(.type == \"PipeWire:Interface:Client\" and .pid == $PID).id"
    CLIENTS=$(echo "$DUMP"|jq -r "$QUERY")
    for CLIENT in $CLIENTS; do
      QUERY=".[]|select(.type == \"PipeWire:Interface:Node\" and .class == \"Stream/Output/Audio\" and .client == $CLIENT).id"
      IDS=$(echo "$DUMP"|jq -r "$QUERY")
      setvol $IDS
    done
  done
fi
