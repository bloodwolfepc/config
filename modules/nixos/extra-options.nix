{ lib, ... }:
{
  options = {
    wallpaper = lib.mkOption {
      default = ../../assets/wallpapers/black.png;
      type = lib.types.path;
    };
  };
}
