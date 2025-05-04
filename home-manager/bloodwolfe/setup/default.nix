{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../modules
    ./lists.nix
  ] ++ (builtins.attrValues outputs.customHomeManagerModules);
  programs.home-manager.enable = true;
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
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
  home = {
    username = lib.mkDefault "bloodwolfe";
    stateVersion = lib.mkDefault "23.11";
    homeDirectory = "/home/bloodwolfe";
    packages = with pkgs; [
      #home-manager
      tree
      ctags
      fzf
      tldr
      jq
      nix-visualize
      nix-tree
      wget
      unzip
      alsa-utils
    ];
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
  };
}
