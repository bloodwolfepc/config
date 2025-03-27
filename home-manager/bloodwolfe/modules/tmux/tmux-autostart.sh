tmux-autostart() {
  if ! command -v tmux &> /dev/null; then
    return 1
  fi
  
  sessions=$(tmux list-sessions 2>/dev/null)
  
  if echo "$sessions" | grep -q "initsession"; then #initsession is true
    if command -v hyprctl &> /dev/null && hyprctl instances | grep -q .; then #hyprland is true
      if ! echo "$sessions" | grep -q "bloodsession"; then #bloodsession is not true
        echo "starting and attaching to bloodsession"
        import-env tmux && tmux new-session -d -s "bloodsession" && tmux attach-session -t "bloodsession" #both will end up being active due to this
      else #bloodsession is true
        if echo "$sessions" | grep -q 'bloodsession.*(attached)'; then #attached to bloodsession is true (somewhere after bloodsession (attached) must occur)
          if echo "$sessions" | grep -q 'initsession.*(attached)'; then
            tmux detach -s initsession
          fi
          return 0
        else #not attached to bloodsession
          echo "attaching to bloodsession"
          tmux attach-session -t "bloodsession"
        fi
      fi
    else #hyprland is not true
      microfetch | dotacat
    fi
  else #initsession is not true
    echo "starting initsession and attaching to initsession"
      #TERM="screen-256color"
      tmux new-session -d -s "initsession" && tmux attach-session -t "initsession"
  fi 
}
if [[ $- == *i* ]]; then
  tmux-autostart
fi
