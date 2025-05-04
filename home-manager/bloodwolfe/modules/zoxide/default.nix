{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "zoxide";
    persistDirs = [
      ".local/share/zoxide"
    ];
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
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
