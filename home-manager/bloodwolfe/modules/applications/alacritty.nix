{
  lib,
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;
    settings = {
      bell = {
        animation = "EaseOutExpo";
        duration = 20;
        color = "#a8a8a8";
        command = {
          program = "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play";
          args = [ "--id=bell" ];
        };
      };
      font = {
        size = lib.mkForce 12.0;
        normal.family = lib.mkForce "unscii";
        normal.style = lib.mkForce "16-full";
        italic.family = lib.mkForce "unscii";
        italic.style = lib.mkForce "16-full";
        bold_italic.family = lib.mkForce "unscii";
        bold_italic.style = lib.mkForce "16-full";
        bold.family = lib.mkForce "unscii";
        bold.style = lib.mkForce "16-full";
      };
      window = {
        opacity = lib.mkForce 0.0;
        blur = lib.mkForce false;
      };
      colors.normal = {
        black = lib.mkForce "0x181818";
        red = lib.mkForce "0xFF0000";
        green = lib.mkForce "0x00FF00";
        yellow = lib.mkForce "0xFFFF00";
        blue = lib.mkForce "0x0000FF";
        magenta = lib.mkForce "0xFF00FF";
        cyan = lib.mkForce "0x00FFFF";
        white = lib.mkForce "0xFFFFFF";
      };
    };
  };
}
