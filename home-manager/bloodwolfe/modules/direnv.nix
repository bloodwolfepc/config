{ ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    config = { };
    nix-direnv = {
      enable = true;
    };
  };
}
