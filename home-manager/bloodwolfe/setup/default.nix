{ inputs, outputs, lib, pkgs, ... }: {
  imports = [ 
    ../modules
    ./lists.nix
  ] 
  ++ (builtins.attrValues outputs.customHomeManagerModules)
    #TODO find a way to import all from dir
    #++ lib.fileset.toList (lib.fileset.fileFiler (file: file.hasExt "nix") ../modules)
    #++ map (dir: ../modules/${dir}/default.nix) builtins.filter (path: builtins.pathExists (path + "/default.nix")) (builtins.listDir ../modules)
  ;
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
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  }; 
  home = {
    username = lib.mkDefault "bloodwolfe";
    stateVersion = lib.mkDefault "23.11";
    homeDirectory = "/home/bloodwolfe";
    packages = with pkgs; [
      home-manager
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
  };
} 
