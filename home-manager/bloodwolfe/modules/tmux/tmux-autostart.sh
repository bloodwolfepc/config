tmux-autostart() {
  if ! command -v tmux &> /dev/null; then
    return 1
  fi

  sessions=$(tmux list-sessions 2>/dev/null || true)
  current_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")

  inside_hyprland=false
  if command -v hyprctl &> /dev/null && hyprctl instances | grep -q .; then
    inside_hyprland=true
  fi

  #is_alacritty_drop=false
  #[[ "$current_session" == "bloodsession" ]] && attached_to_bloodsession=true
  #it may be possable to set this based on a jq output for a new window created, determining if it is newset,
  #then seeing if it is alacritty_drop 

  #maybe we can birth the drop session and send an env var into it though hdrop starting
  
  #it may be better to seperate the session managment into how each terminal is initialized

  initsession_exists=false
  echo "$sessions" | grep -q "^initsession:" && initsession_exists=true

  bloodsession_exists=false
  echo "$sessions" | grep -q "^bloodsession:" && bloodsession_exists=true

  attached_to_initsession=false
  [[ "$current_session" == "initsession" ]] && attached_to_initsession=true

  attached_to_bloodsession=false
  [[ "$current_session" == "bloodsession" ]] && attached_to_bloodsession=true


  if [[ "$initsession_exists" == true ]]; then
    if [[ "$inside_hyprland" == true ]]; then
      if [[ "$bloodsession_exists" == true ]]; then
        if [[ "$attached_to_bloodsession" == true ]]; then
          echo ":x:"
          #if [[ "$attached_to_initsession" == true ]]; then
          #  tmux detach -s initsession
          #fi
          #return 0
        else
          echo "attaching to bloodsession"
          exec tmux new-session -A -t "bloodsession"
        fi
      else
        echo "starting and attaching to bloodsession"
        import-env tmux
        exec tmux new-session -s "bloodsession"
      fi
    # else
    #   microfetch | dotacat
    fi
  else
    exec tmux new-session -s "initsession"
  fi
}
if [[ $- == *i* ]]; then
  tmux-autostart
fi
