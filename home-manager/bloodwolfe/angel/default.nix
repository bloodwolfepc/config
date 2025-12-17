{ pkgs, ... }:
{
  imports = [
    ../modules
  ];
  wayland.windowManager.hyprland =
    let
      mon0 = "desc:LG Electronics LG ULTRAGEAR 510RMLM9B112";
      monl1 = "desc:BOE 0x0A1D";
      monl2 = "desc:YUK REALTEK demoset-1";
    in
    {
      extraConfig = ''
        submap = MONITOR
          bindi = ,f, focusmonitor, ${mon0}
          bindi = ,d, focusmonitor, ${monl1}
          bindi = ,s, focusmonitor, ${monl2}
        submap = escape
      '';
      settings = {
        monitor = [
          "${mon0}, 2560x1440@240, 0x0, 1"
          "${monl1}, 2560x1600@120, -2560x0, 1"
          "${monl2}, 1920x1080@60, -4480x0, 1"
        ];
        input.touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
        };
        input.tablet = {
          transform = "6";
          region_size = "1920 1268";
        };
      };
    };
  home.packages = with pkgs; [
    xf86_input_wacom
  ];
}
