{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nvim = inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default;
  envPath = "${config.xdg.configHome}/nvim/.env";
in
{
  home.packages = [
    nvim
    pkgs.vectorcode
    pkgs.luaPackages.lua-utils-nvim
    pkgs.luaPackages.pathlib-nvim
  ];
  home = {
    sessionVariables = {
      EDITOR = "${nvim}/bin/nvim";
    };
    shellAliases = {
      "vi" = "${nvim}/bin/nvim";
      "no" = "${nvim}/bin/nvim $HOME/notebook/index.norg";
    };
    persistence = {
      "/persist".directories = [
        ".local/share/nvim"
      ];
    };
  };

  sops = {
    secrets."openai-auth" = { };
    templates."nvim.env" = {
      content = ''
        OPENAI_API_KEY=${config.sops.placeholder.openai-auth}
      '';
      path = "${envPath}";
      mode = "0400";
    };
  };
}
