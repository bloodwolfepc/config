tmux-autostart() {
  if ! command -v tmux &> /dev/null; then
    return 1
  fi
  
  sessions=$(tmux list-sessions 2>/dev/null)
  
  if ! echo "$sessions" | grep -q "initsession"; then
    echo "starting initsession"
    tmux new-session -d -s "initsession"
  #else
    #echo "attaching to initsession"
    #tmux attach-session -t "initsession"
  fi
  
  if ! echo "$sessions" | grep -q "bloodsession"; then
    if command -v hyprctl &> /dev/null && hyprctl instances | grep -q .; then
      echo "starting bloodsession"
      tmux new-session -d -s "bloodsession"
    #else
      #echo "attaching to bloodsession"
      #tmux attach-session -t "bloodsession" 2>/dev/null
    fi
  fi
  tmux attach-session -t "bloodsession" 2>/dev/null || tmux attach-session -t "initsession"
  return 0
}
if [[ $- == *i* ]]; then
  tmux-autostart
fi

#if command -v tmux &> /dev/null; then
#  if tmux list-sessions | grep -q "initsession"; then
#    if tmux list-session | grep -q "bloodsession"; then
#      return
#    elif command -v hyprctl &> /dev/null && hyprctl instances | grep -q .; then
#      tmux new-session -s "bloodsession"
#    else 
#      return
#    fi
#    tmux new-session -s "initsession"
#  else
#    return
#  fi
#fi

#if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then     #&& [ -n "$WAYLAND_SESSION" ]; then
#  tmux attach-session -t bloodsession || tmux new-session -s bloodsession
#fi


#if command -v tmux &> /dev/null then 
#  if [ -z "$TMUX" ]; && [ -n "$WAYLAND_SESSION" ]; then
#    echo "-bloodsession-" && 
#    tmux attach-session -t bloodsession || tmux new-session -s bloodsession
#  elseif [ -z "$TMUX" ]; then
#    echo "init-session" && TMUX_INIT=1
#    tmux attach-session -t init-session || tmux new-session -s init-session
#  fi
#fi


