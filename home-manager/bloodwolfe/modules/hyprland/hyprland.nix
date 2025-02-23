#TODO clipboard history management, screenshots
# bind that:
#moves firefox to a position of the aftive workspace and another to return it
#wvkbd-mobintl -L 400 -fn Unscii -bg 000000 -fg 000000 -fg-sp 000000 -press 000000|00 -press-sp 000000|00
{ pkgs, lib, config }: let
  attrs = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    settings = {
      #env = [
      #  "AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:07:00.0-card"
      #];
      #env = [
	    #  "XCURSOR_SIZE,24"
	    #  "QT_QPA_PLATFORMTHEME,qt6ct"
	    #  "QT_QPA_PLATFORM=wayland;xcb"
	    #  "GDK_BACKEND=wayland,x11"
	    #  "SDL_VIDEODRIVER=wayland"
	    #  "CLUTTER_BACKEND=wayland"
	    #  "XDG_CURRENT_DESKTOP=sway"
	    #  "XDG_DESSION_TYPE=wayland"
	    #  "XDG_SESSION_DESKTOP=Hyprland"
	    #  "WLR_DRM_NO_ATOMIC,1"
	    #  "WLR_DRM_NO_ATOMIC,1"
      #  "MOZ_ENABLE_WAYLAND=1"
      #];
      exec-once = [
        "hyprctl dispatch submap INS"
        "${pkgs.swww}/bin/swww daemon"
        "${pkgs.swww}/bin/swww img = ${config.wallpaper}"
        "xrandr --output DP-1 --primary"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "lxqt-policykit-agent"
      ];
      general = {
        allow_tearing = true;
        #border_size = "0";
        #gaps_in = "0";
        #gaps_out = "0";
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        permanent_direction_override = true;
      };
      decoration = {
        fullscreen_opacity = "1";
        blur.enabled = false;
        drop_shadow = false;
      };
      debug = {
        suppress_errors = true; #hyprctl seterror diasable
        disable_logs = false;
        disable_time = false;
        enable_stdout_logs = true;
      };
      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = true;
        workspace_swipe_cancel_ratio = 0.15;
        workspace_swipe_create_new = true;
      };
      xwayland.force_zero_scaling = true;
      binds.allow_workspace_cycles = true; 
      animations.enabled = false;
      cursor = {
        inactive_timeout = 0.5;
        hide_on_key_press = true;
        hide_on_touch = true;
      };
      input = { #hyprctl devices
        kb_layout = "us";
        follow_mouse = "1";
        sensitivity = "0";
        accel_profile = "flat";
        #touchpad = {
        #  natrual_scroll = true;
        #  disable_while_typing = false;
        #  scroll_factor = 0.5;
        #};
        #misc = {
        #  disable_hyprland_logo = true;
        #  disable_splash_rendering = true;
        #};
      };
      monitor = map
        (m:
          let 
            resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
            position = "${toString m.x}x${toString m.y}";
          in
          "${m.name},${if m.enabled then "${resolution},${position},1" else "disable"}"
        )
        (config.monitors);
    };
  };
  in {
  inherit attrs;
}
