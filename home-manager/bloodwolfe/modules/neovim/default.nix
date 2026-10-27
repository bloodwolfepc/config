{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  live = "${config.home.homeDirectory}/src/january-nvim";
  configPath = "${config.xdg.configHome}/january-nvim";
  nvim = inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    configPath = if config.dotfiles.mutable then configPath else inputs.neovim.outPath;
  };
  envPath = "${config.xdg.configHome}/nvim/.env";
in
{
  home.activation.januaryNvimSource = lib.mkIf config.dotfiles.mutable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      source=${inputs.neovim.outPath}
      if [[ -f "${live}/flake.nix" && -d "${live}/lua/jnvconf" ]]; then
        source=${live}
      else
        echo "warning: ${live} is incomplete; using pinned Neovim configuration" >&2
      fi

      if [[ -e "${configPath}" && ! -L "${configPath}" ]]; then
        echo "error: refusing to replace non-symlink ${configPath}" >&2
        exit 1
      fi
      run mkdir -p "$(dirname "${configPath}")"
      run rm -f "${configPath}.home-manager"
      run ln -sT "$source" "${configPath}.home-manager"
      run mv -Tf "${configPath}.home-manager" "${configPath}"
    ''
  );

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
