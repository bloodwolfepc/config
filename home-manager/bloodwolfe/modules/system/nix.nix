{
  lib,
  config,
  pkgs,
  ...
}:
{
  home.persistence."/persist/home/bloodwolfe".directories = [
    ".cache/nix-index"
  ];
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  packages = with pkgs; [
    nix-output-monitor
    nvd
  ];
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/src/config";
    clean = {
      enable = true;
      extraArgs = "--keee-since 4d --keep 3";
    };
  };
}
