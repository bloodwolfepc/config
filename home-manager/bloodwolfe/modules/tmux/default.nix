{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "tmux";
    stylix.targets.tmux.enable = false;
    packages = with pkgs; [
      sesh
      microfetch
      (writeShellScriptBin "import-env" (builtins.readFile ./import-env.sh))
    ];
    programs.tmux =
      let
        matryoshka = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "matryoshka";
          version = "unstable-2025-01-04";
          src = pkgs.fetchFromGitHub {
            owner = "niqodea";
            repo = "tmux-matryoshka";
            rev = "main";
            hash = "sha256-r1p8soVcG+GFvacubr3R7eHqzaUwSfbvgvWFeYXntZQ=";
          };
          meta = {
            license = pkgs.lib.licenses.mit;
            description = "Plugin for nested tmux workflows";
          };
        };
      in
      {
        enable = true;
        shell = "${pkgs.zsh}/bin/zsh";
        terminal = "screen-256color";
        historyLimit = 100000;
        clock24 = true;
        keyMode = "vi";
        prefix = "C-Space";
        shortcut = "a";
        baseIndex = 1;
        aggressiveResize = true;
        escapeTime = 0;
        disableConfirmationPrompt = true;
        mouse = true;
        tmuxinator.enable = true;
        sensibleOnTop = true;
        #secureSocket = false;
        plugins =
          with pkgs.tmuxPlugins;
          [
            #https://github.com/niqodea/tmux-matryoshka?tab=readme-ov-file
            vim-tmux-navigator
            tmux-thumbs # pfx+space
            fzf-tmux-url # pfx+u
            fuzzback # pfx+? - fuzzy seach backwards
            extrakto # pfx+tab
            copycat # pfx+/ - regex
            yank
            open # o for XDG, ctrl+o for $EDITOR, S+s for search
            {
              plugin = jump; # pfx+g
              extraConfig = ''
                set -g @jump-key 'g'
              '';
            }
            {
              plugin = tmux-fzf; # pfx+f
              extraConfig = ''
                unbind f
                TMUX_FZF_LAUNCH_KEY="f"
                #bind F find-window (needs args)
              '';
            }
            {
              plugin = resurrect;
              #https://github.com/spywhere/tmux-named-snapshot
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
          ]
          ++ [ matryoshka ];
        extraConfig = ''
          bind Escape copy-mode
          bind -Tvi-copy 'v' send -X begin-selection
          bind -Tvi-copy 'y' send -X copy-selection
          unbind p
          bind p paste-buffer
          bind P prev

          unbind %
          bind b split-window -h -c "#{pane_current_path}"
          unbind '"'
          bind v split-window -v -c "#{pane_current_path}"
          #unbind c
          #bind c new-window -c "#{pane_current_path}"


          bind -r h resize-pane -L 5
          bind -r j resize-pane -D 5
          bind -r k resize-pane -U 5
          bind -r l resize-pane -R 5
          #bind H swap-pane -L
          bind J swap-pane -D
          bind K swap-pane -U
          #bind l swap-pane -R
          unbind z
          bind -r m resize-pane -Z

          set-window-option -g mode-keys vi
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

          #set -g allow-passthrough on
          set -s set-clipboard on

          unbind t
          bind-key T clock-mode
          bind-key t set-option status
          set -g status off

          bind C-m break-pane
          bind 'z' command-prompt -p "move pane to:" "move-pane -t ':%%'"

          bind C-c send-keys 'C-l'
          #set-window-option -g visual-bell on
          #set-window-option -g bell-action other
          #set-hook -g alert-bell 'run-shell "canberra-gtk-play --id=bell"'
        '';
      };
    programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
      builtins.readFile ./tmux-autostart.sh
    );
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
