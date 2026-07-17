{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.home-manager.enable = true;
  home.sessionVariables.FLAKE = "${config.home.homeDirectory}/src/config";
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays ++ [ inputs.millennium.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  # home.persistence."/persist".directories = [
  #   ".cache/nix-index/files"
  # ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/src/config";
    clean = {
      enable = true;
      extraArgs = "--keee-since 4d --keep 3";
    };
  };

  home = {
    username = lib.mkDefault "bloodwolfe";
    stateVersion = lib.mkDefault "23.11";
    homeDirectory = "/home/bloodwolfe";
    packages = with pkgs; [
      nix-output-monitor
      nvd
      nix-visualize
      nix-tree
    ];
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    shellAliases = {
      ns = "nix-shell --command zsh -p";
      nie = "nix instantiate --eval";
      nr = "nix repl";
    };
  };
}
