{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cava
    playerctl
    (pavucontrol.override { withLibcanberra = true; })
    easyeffects
    qpwgraph
    ardour
    carla
    sfizz
    orca-c
    csound
    glicol-cli
    puredata
    plugdata
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
    ladspaPlugins
    AMB-plugins
    aether-lv2
    gxplugins-lv2
    guitarix
    #distrho #includes vitalium and juce #broke
    supercollider
    airwindows-lv2
    tap-plugins
    zynaddsubfx
    helm # broke
    x42-gmsynth
    yoshimi
    coppwr

    #zrythm
    soundfont-fluid
    wolf-shaper
  ];
  home.persistence."/persist".directories = [
    "soundfiles"
    ".config/falkTX"
    ".config/ardour8"
    ".cache/ardour8"

  ];
  wayland.windowManager.hyprland.settings.windowrule = [
    # fixes draggables in ardour
    #"match:xwayland 1, noinitialfocus"
  ];
}
