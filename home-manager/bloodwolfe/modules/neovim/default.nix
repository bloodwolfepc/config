{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nvim = inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    configPath = config.dotfiles.sourceAt "${config.home.homeDirectory}/src/january-nvim" inputs.neovim.outPath;
  };
  envPath = "${config.xdg.configHome}/nvim/.env";
in
{
  home.packages = [
    nvim
    pkgs.lemonade
    pkgs.vectorcode
    pkgs.luaPackages.lua-utils-nvim
    pkgs.luaPackages.pathlib-nvim
  ];
  xdg.configFile."lemonade.toml".text = ''
    host = '127.0.0.1'
  '';

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
