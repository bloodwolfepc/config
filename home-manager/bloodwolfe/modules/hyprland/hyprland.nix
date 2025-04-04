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
      exec-once = [
        "hyprctl dispatch submap INS"
        "hyprctl dispatch workspace 4"
        "${pkgs.alacritty}/bin/alacritty"
        "systemctl restart --user swww.service"
        #"${pkgs.swww}/bin/swww img ${config.wallpaper}"
        "xrandr --output DP-1 --primary"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "lxqt-policykit-agent"
      ];
      general = {
        allow_tearing = true;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        #vrr = 1;
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        permanent_direction_override = true;
        smart_resizing = false;
      };
      decoration = {
        fullscreen_opacity = "1";
        blur.enabled = false;
      };
      debug = {
        suppress_errors = false;
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
      input = {
        kb_layout = "us";
        follow_mouse = "1";
        sensitivity = "0";
        accel_profile = "flat";
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
#hyprctl keyword monitor DP-3,1920x1080@144,0x0,1
