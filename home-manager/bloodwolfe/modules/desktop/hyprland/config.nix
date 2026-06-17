{
  lib,
  ...
}:
{
  wayland.windowManager.hyprland.extraConfig =
    let
      const = ''
        bindm = , mouse:272, movewindow
        bindm = , mouse:273, resizewindow
      '';
      kb_nml = "super_l";
    in
    lib.mkBefore ''
      submap = INS
        bindi = , ${kb_nml}, submap, NML
      submap = escape
      submap = NML
        ${const}
      submap = escape
      submap = FWS
        ${const}
      submap = escape
      submap = MVWS
        ${const}
      submap = escape
      submap = RSZA
        ${const}
      submap = escape
      submap = MVA
        ${const}
      submap = escape
      submap = SS
        ${const}
      submap = escape
      submap = SWA
        ${const}
      submap = escape
      submap = UTIL
        ${const}
      submap = escape
      submap = FMON
        ${const}
      submap = escape
      submap = MENU
        ${const}
      submap = escape
      submap = SWTM
        ${const}
      submap = escape

      windowrule {
        name = ueberzugpp
        match:class = ^(ueberzugpp.*)$
        float = true
        no_anim = true
        border_size = 0
        no_focus = true
        no_follow_mouse = true
        no_blur = true
      }
      windowrule {
        name = wezterm-drop
        match:class = wezterm-drop
        border_size = 0
      }
    '';
}
