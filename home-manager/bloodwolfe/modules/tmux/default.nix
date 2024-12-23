#TODO extra configuration, start from 1

{ lib, config, pkgs, ... }: let 
  #normalMode = mkShellScriptbin ''
  #  if [ $1 = "e" ]; then
  #    if [ $2 = "j" ]; then
  #      tmux split-window -v -c "{pane_current_path}"
  #    elif [ $2 = "l" ]; then
  #      tmux split-window -h -c "{pane_current_path}"
  #    fi
  #  fi
  #'';
  attrs = lib.custom.mkHomeApplication {
    name = "tmux";
    programs.tmux = {
      enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "screen-256color";
      historyLimit = 100000;
      clock24 = true;
      keyMode = "vi";
      prefix = "C-Space";
      disableConfirmationPrompt = true;
      mouse = false;
      tmuxinator.enable = true;
      sensibleOnTop = true;
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        tmux-thumbs
        tmux-fzf
        fzf-tmux-url
        fuzzback
        extrakto
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-startegy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '30'
          '';
        }
        ];
      # bind-key mod4 or Escape command-prompt "${normalMode} %%" #jk
      extraConfig = ''
        set-window-option -g mode-keys vi

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        unbind %
        bind b split-window -h -c "{pane_current_path}"
        unbind '"'
        bind v split-window -v -c "{pane_current_path}"

        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5
        bind -r m resize-pane -Z

        set -g status off
      '';
    };
    programs.zsh.initExtra = lib.mkIf config.programs.zsh.enable ''
      if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi
    '';
    #programs.hyprland.extraConfig = (lib.mkIf config.programs.hyprland.enable) lib.mkBefore ''
    #  submap = NML
    #    bindi = , SPACE , sendshortcut , CONTROL, SPACE , ^(Alacritty)&
    #  submap = escape
    #'';
    inherit config;
  };
in {
  inherit (attrs) options config;
}
