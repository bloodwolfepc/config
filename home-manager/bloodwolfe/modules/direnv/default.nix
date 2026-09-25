{ config, ... }: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    config = {
      whitelist.prefix = [
        "${config.home.homeDirectory}/src"
        "${config.home.homeDirectory}/notebook"
      ];
    };
    nix-direnv = {
      enable = true;
    };
  };
}
