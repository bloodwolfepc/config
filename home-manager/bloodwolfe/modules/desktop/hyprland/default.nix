{
  pkgs,
  lib,
  outputs,
  config,
  ...
}:
{
  imports = [
    ./pass-oneshots.nix
    ./config.nix
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    settings = {
      exec-once = [
        "hyprctl dispatch submap INS"
        "hyprctl dispatch workspace 4"
        "${pkgs.alacritty}/bin/alacritty"
        "systemctl restart --user swww.service"
        "xrandr --output DP-1 --primary"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "lxqt-policykit-agent"
        "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -i desktop-login"
        "hdrop -b -f alacritty --class alacritty_drop"
        "wl-paste -t text -w xclip -selection clipboard" # fix for clipboard
      ];
      general = {
        allow_tearing = true;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        render_unfocused_fps = 60;
        enable_anr_dialog = false;
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
        full_cm_proto = true;
        suppress_errors = false;
        disable_logs = false;
        disable_time = false;
        enable_stdout_logs = true;
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
    };
  };
  home.sessionVariables = {
    AQ_DRM_DEVICES = "/dev/dri/card1"; # "/dev/dri/by-path/pci-0000:07:00.0-card"
    HL_RESIZE = 100;
    HL_MOVE = 100;
  };
  xdg = {
    enable = true;
    portal =
      let
        hyprland = config.wayland.windowManager.hyprland.package;
      in
      {
        enable = true;
        configPackages = [
          hyprland
        ];
        config.hyprland = {
          default = [
            #"wlr"
            #"gtk"
          ];
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
      };
  };
  home.packages =
    with pkgs;
    [
      (writeShellScriptBin "pc" ''
        ${hyprland}/bin/Hyprland
      '')
      libnotify
      (writeShellScriptBin "toggle-touchpad" (builtins.readFile ./sh/touchpad.sh))
      (writeShellScriptBin "hl-util.sh" (builtins.readFile ./sh/hl-util.sh))
      wayvnc
      wl-mirror
      grimblast
      wl-clipboard
      xorg.xrandr
      hyprpicker
      imagemagick
      hdrop
      lxqt.lxqt-policykit
    ]
    ++ (with outputs.customPackages; [
      hyprfreeze
    ]);
  services.swww = {
    enable = true;
  };
  services.cliphist = {
    enable = true;
  };
}
