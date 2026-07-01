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
      # {
      #   name = "zsh-nix-shell";
      #   file = "nix-shell.plugin.zsh";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "chisui";
      #     repo = "zsh-nix-shell";
      #     rev = "v0.8.0";
      #     sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
      #   };
      # }

      #zsh-autopair
    ];
    initContent = lib.mkBefore ''
      function zvm_config() {
        ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
        ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
        ZVM_VI_OPPEND_ESCAPE_BINDKEY=jk
      }
      eval "$(starship init zsh)"

      export OPENAI_API_KEY="$(cat ${config.sops.secrets."openai-auth".path})"
      export KAGI_API_KEY="$(cat ${config.sops.secrets."kagi-api".path})"
    '';
  };
  sops.secrets = {
    "openai-auth" = { };
    "kagi-api" = { };
  };
  home = {
    packages = with pkgs; [
      starship
      (writeShellScriptBin "source-new-env-vars" ''
        unset __HM_SESS_VARS_SOURCED && source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
      '')
    ];
    sessionVariables.STARSHIP_CONFIG = "$FLAKE/hm-modules/zsh/starship.toml"; # "${config.xdg.configHome}/starship/starship.toml";
    file.".config/starship.toml".source = ./starship.toml;
  };
}
