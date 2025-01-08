{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "daw";
    pcExecOnce = [
      "carla ${config.home.homeDirectory}/carla/default.carxp --no-gui"
    ];
    packages = with pkgs; [

      cli-visualizer
      playerctl
      pavucontrol
      qpwgraph

      #ardour
      musescore
      yabridge
      yabridgectl
      carla
      sfizz
      orca-c
      #csound
      glicol-cli
      puredata
      plugdata
      #zexy
      #timbreid 
      #maxlib 
      #cyclone 
      #faust
      surge 
      vital 
      cardinal 
      odin2
      geonkick
      x42-avldrums
      freepats
      drumgizmo
      freepats
      mda_lv2
      airwindows-lv2
      lsp-plugins
      zam-plugins
      x42-plugins
      calf
      CHOWTapeModel
      ladspaPlugins
      AMB-plugins
      aether-lv2
      gxplugins-lv2
      guitarix
      #soundux #removed due to being unmaintained
      #distrho #includes vitalium and juce #broke
      supercollider
      airwindows-lv2
      tap-plugins
      zynaddsubfx
      #helm #broke
      x42-gmsynth
      yoshimi
      eq10q
      sonobus
      coppwr
      neothesia
      
      #UNPACKAGED
      #wolf-spectrum
      
      zrythm
      soundfont-fluid
      #openutau
      wolf-shaper

    ];
    syncDirs = [
      ".local/share/vital" #~/.local/share/vital/User/{Wavetables,Presets}
      ".config/falkTX" 
      ".config/ardour8"
      ".cache/ardour8"
      ".config/MuseScore"
      ".local/share/MuseScore"
      ".cache/MuseScore"
      ".local/share/OpenUtau"

      "ardour"
      "vital"
      "sfz"
      "carla"
      "orca"
      "sheetmusic"
      "soundfiles"
    ];
    extraConfig = {
      wayland.windowManager.hyprland = {
        settings.windowrulev2 = [
          "noinitialfocus , xwayland:1" #fixes draggables in ardour
        ];
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
