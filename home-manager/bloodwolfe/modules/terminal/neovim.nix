{
  pkgs,
  inputs,
  ...
}:
let
  nvim = inputs.neovim.packages.${pkgs.system}.default;
in
{
  home.packages = [
    nvim
    pkgs.luaPackages.lua-utils-nvim
    pkgs.luaPackages.pathlib-nvim
  ];
  home = {
    sessionVariables = {
      EDITOR = "${nvim}/bin/nvim";
    };
    shellAliases = {
      # "vi" = "${nvim}/bin/nvim";
      # "no" = "${nvim}/bin/nvim -c 'Neorg index'";
      # "nj" = "${nvim}/bin/nvim -c 'Neorg journal'";
      "vi" = "${nvim}/bin/nvim";
      "av" = ''
        'nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"' 
      '';
    };
    persistence = {
      "/persist".directories = [
        ".local/share/nvim"
      ];
    };
  };
}
