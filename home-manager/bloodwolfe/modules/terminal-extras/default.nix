{ lib, config, pkgs, outputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "terminal-extras";
    packages = with pkgs; [
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
    inherit config;
  };
in {
  inherit (attrs) options config;
}
