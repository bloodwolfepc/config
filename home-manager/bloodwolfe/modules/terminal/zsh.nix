{
  lib,
  config,
  pkgs,
  ...
}:
{
  sops.secrets."openai-auth" = { };
  name = "zsh";
  programs.zsh = {
    enable = true;
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      #zsh-autopair
    ];
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
    };
    syntaxHighlighting.enable = true;
    history = {
      save = 10000;
      size = 10000;
      path = "/persist${config.home.homeDirectory}/.zhistory";
      expireDuplicatesFirst = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    profileExtra = ''	'';
    shellAliases = {
      ns = "nix-shell --command zsh -p";
      gvi = "nix run github:evilcatlawyer/nixvim";
      lvi = "nix run /home/bloodwolfe/projects/nixvim --";
      vi = "nvim";
      td = "task";
      syst = "systemctl status";
      systu = "systemctl status --user";
      jctl = "journalctl -xeu";
      jctlu = "journalctl --user -xeu";
      hist = "vi /persist/home/bloodwolfe/.zhistory";
      update-secrets = ''
        cd ~/src/secrets
        git add .
        git commit -m "update-secrets"
        git push
        cd $FLAKE
        nix flake update secrets 
        #cd -
        #cd -
      '';
      sync-permissions = "
        sudo chown -R bloodwolfe:syncthing /sync/home/bloodwolfe &&
        sudo chmod -R 770 /sync/home/bloodwolfe
      ";
      remove-dangling-symlinks = "find . -xtype l -delete";
      cat = "dotacat";
      nia = "nix instantiate --eval";
      nr = "nix repl";
      dirty = "watch grep -e Dirty: -e Writeback: /proc/meminfo";
      rsync = "rsync -r --info=progress2 --info=name0";
      slowcat = ''perl -pe "system 'sleep .025'"'';
    };
    initContent = lib.mkBefore ''
      function zvm_config() {
        ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
        ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
        ZVM_VI_OPPEND_ESCAPE_BINDKEY=jk
      }
      prompt walters 
      PROMPT='%F{green}%n%f@%F{magenta}%m%f %F{blue}%B%~%b%f %# '
      eval "$(zoxide init zsh)"
      export OPENAI_API_KEY="$(cat ${config.sops.secrets."openai-auth".path})"
    '';
  };
  #programs.atuin = {
  #  enable = true;
  #  settings = {
  #    auto_sync = true;
  #    sync_frequency = "5m";
  #    sync_addresss = "";
  #    search_mode = "prefix";
  #  };
  #};

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
  programs.zsh.shellAliases = {
    z = "cd";
  };

}
