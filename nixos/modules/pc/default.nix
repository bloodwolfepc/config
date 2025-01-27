{ pkgs, inputs, ... }: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };
  security.polkit.enable = true;
  xdg.portal = {
    enable = true;
    #config = {
    #  common.default = [ "gtk" ];
    #};
  };
  programs.light.enable = true;
  programs.ydotool.enable = true;
}
