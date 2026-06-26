{ config, pkgs, ... }:
{
  sops = {
    secrets."openai-auth" = { };
    secrets."kagi-api" = { };
    templates."aichat.env" = {
      content = ''
        OPENAI_API_KEY=${config.sops.placeholder.openai-auth}
      '';
      path = ".config/aichat/.env";
      mode = "0400";
    };
  };

  home = {
    shellAliases = {
      ai = "aichat";
      ais = "aichat -s";
    };
    sessionVariables = {
      OPENAI_API_KEY = "$(cat ${config.sops.secrets."openai-auth".path})";
      KAGI_API_KEY = "$(cat ${config.sops.secrets."kagi-api".path})";
    };
    packages = with pkgs; [
      aichat
    ];
    persistence."/persist".directories = [
      ".config/aichat"
    ];
  };

  systemd.user.tmpfiles.rules = [
    "d ${config.xdg.configHome}/aichat 0700 ${config.home.username} users -"
  ];
}
