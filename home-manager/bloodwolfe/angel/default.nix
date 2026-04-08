{ pkgs, ... }:
{
  imports = [
    ../modules
  ];
  wayland.windowManager.hyprland =
    let
      mon0 = "desc:LG Electronics LG ULTRAGEAR 510RMLM9B112";
      monl1 = "desc:BOE 0x0A1D";
    in
    {
      extraConfig = ''
        submap = MONITOR
          bindi = ,f, focusmonitor, ${mon0}
          bindi = ,d, focusmonitor, ${monl1}
        submap = escape
        submap = SEND_TO_MONITOR
          bind = , f, movecurrentworkspacetomonitor, ${mon0}
          bind = , d, movecurrentworkspacetomonitor, ${monl1}
        submap = escape
      '';
      settings = {
        monitor = [
          "${mon0}, 2560x1440@240, 0x0, 1"
          "${monl1}, 2560x1600@120, -2560x0, 1"
        ];
        input.touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
        };
        input.tablet = {
          transform = "6";
          region_size = "1920 1268";
          output = "current";
        };
      };
    };
  home.packages = with pkgs; [
    xf86_input_wacom
    wineWowPackages.stagingFull
    spotify
  ];
}
#   device = {
#     name = "wacom-intuos-pro-m-pen"
# };
