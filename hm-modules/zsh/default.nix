{
  lib,
  config,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
    };
    syntaxHighlighting = {
      enable = true;
    };
    history = {
      save = 10000;
      size = 10000;
      path = "/persist${config.home.homeDirectory}/.zhistory";
      expireDuplicatesFirst = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      #zsh-autopair
    ];
    initContent = lib.mkBefore ''
      function zvm_config() {
        ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
        ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
        ZVM_VI_OPPEND_ESCAPE_BINDKEY=jk
      }
      # prompt walters 
      # PROMPT='%F{green}%n%f@%F{magenta}%m%f %F{blue}%B%~%b%f %# '
      eval "$(starship init zsh)"
    '';
  };
  home = {
    packages = with pkgs; [
      starship
    ];
    sessionVariables.STARSHIP_CONFIG = "$FLAKE/hm-modules/zsh/starship.toml"; # "${config.xdg.configHome}/starship/starship.toml";
    file.".config/starship.toml".source = ./starship.toml;
  };
}
