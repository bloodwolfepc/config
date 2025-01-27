{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "zsh";
    programs.zsh = {
    	enable = true;
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
      enableCompletion = true;
      enableVteIntegration = true;
      autosuggestion = {
        enable = true;
        highlight = "fg=#ff00ff,bg=cyan,bold,underline";
      };
      #defaultKeymap = "viins";
      #completionInit = "autoload -U compinit && compinit && promptinit";
      syntaxHighlighting.enable = true;
    	history = {
    		save = 10000;
    		size = 10000;
    		path = "/persist${config.home.homeDirectory}/.zhistory";
        expireDuplicatesFirst = true;
    	}; 
      historySubstringSearch = {
        enable = true;
        #searchDownKey = [ "^j" ];
        #searchUpKey = [ "^k" ];
      };
    	profileExtra = ''
        ${pkgs.hyfetch}/bin/hyfetch
    	'';
    	shellAliases = {
        ns = "nix-shell --command zsh -p";
    		gvi = "nix run github:evilcatlawyer/nixvim"; 
        lvi = "nix run /home/bloodwolfe/projects/nixvim --";
        vi = "nvim";
        td = "task";
        sync-permissions = "
          sudo chown -R bloodwolfe:syncthing /sync/home/bloodwolfe &&
          sudo chmod -R 770 /sync/home/bloodwolfe
        ";
        remove-dangling-symlinks = "find . -xtype l -delete";
        install-tf2-hud = "
        cd ~/.local/share/Steam/steamapps/common/Team\ Fortress\ 2/tf/custom
        wget https://github.com/CriticalFlaw/flawhud/releases/download/2024.0501/flawhud.zip
        unzip ./flawhud.zip
        rm ./flawhud.zip
        cd
        ";
        install-tf2-hud-flatpak = "
        cd ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Team\ Fortress\ 2/tf/custom
        wget https://github.com/CriticalFlaw/flawhud/releases/download/2024.0501/flawhud.zip
        unzip ./flawhud.zip
        rm ./flawhud.zip
        cd
        ";
    
    		#cat-og = "${pkgs.cat}/bin/cat";
    		cat = "lolcat";
        nia = "nix instantiate --eval";
        nr = "nix repl";
    
    		#cd-og = "${pkgs.cd}/bin/cd";
        dirty = "watch grep -e Dirty: -e Writeback: /proc/meminfo";
        rsync = "rsync -r --info=progress2 --info=name0";
        #slowcat = "perl -pe "system 'sleep .025'"";
    	};
      #TODO change zsh readkey engine
      initExtraFirst = ''
        function zvm_config() {
          ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
          ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
          ZVM_VI_OPPEND_ESCAPE_BINDKEY=jk
        }
      '';
    	initExtra = ''
        prompt walters 
        PROMPT='%F{green}%n%f@%F{magenta}%m%f %F{blue}%B%~%b%f %# '
        eval "$(zoxide init zsh)"
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
    inherit config;
  };
in {
  inherit (attrs) options config;
}
