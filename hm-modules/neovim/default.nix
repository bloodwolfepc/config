{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nvim = inputs.neovim.packages.${pkgs.system}.default;
  envPath = "${config.xdg.configHome}/nvim/.env";
  src-nvim = (
    pkgs.writeShellScriptBin "src-nvim" ''
      exec nix run "$HOME/src/january-nvim" -- "$@"
    ''
  );
in
{
  home.packages = [
    nvim
    src-nvim
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
      "svi" = "${src-nvim}/bin/src-nvim";
      "no" = "${nvim}/bin/nvim $HOME/notebook/index.norg";
      "sno" = "${src-nvim}/bin/src-nvim $HOME/notebook/index.norg";
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
