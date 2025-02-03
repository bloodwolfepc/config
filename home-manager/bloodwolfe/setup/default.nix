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


      lolcat
      dotacat

      #lolcrab
      figlet
      sl
      #cowsay
      asciiquarium
      gay
      neofetch
      #https://github.com/poetaman/arttime

      catimg
      jp2a
      ascii-image-converter
      goat #convert to svg diagrams

      era
      tenki
      rsclock #clock-rs
      tty-clock

      bat
      viddy
      moar
      toolong
      dust
      ncdu
      eza

      bsdgames
      nbsdgames

      unimatrix
      cmatrix
      tmatrix
      neo

      pipes-rs #pipes

      libresprite
      #aseprite

      ascii-draw

      #nyancat

      #fortune
      #fortune-kind
      #taoup

      asciicam

      glances
      gtop
      curlie

      #wakatime
      
    ] ++ (with outputs.customPackages; [
      ascii-rain
      durdraw
    ]);
  };
} 
