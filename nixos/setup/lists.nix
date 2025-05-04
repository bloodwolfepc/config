{ lib, ... }:
{
  options.sysglobals.list = {
    require-nixos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    require-pc = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    srv-progs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    used-progs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    gaming-progs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = {
    sysglobals = {
      list = {
        require-nixos = [
          "nh"
          "nix"
          "sops"
          "locale"
          "ssh"
          "impermanence"
          "ephemeral-btrfs"
          "yubikey"
          "kanata"
        ];
        require-pc = [
          "hyprland"
          "umc-404-extensive-audio"
          "printing"
          "bluetooth"
        ];
        srv-progs = [
          "virtualisation"
        ];
        used-progs = [
          "android-utils"
          "flatpak"
          "kde-connect"
        ];
        gaming-progs = [
          "gaming"
          "gamescope"
          "steam"
        ];
      };
    };
  };
}
