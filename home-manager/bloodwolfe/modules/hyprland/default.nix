{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  modesetting = import ./modesetting.nix { inherit pkgs lib config; };
  kb-globals = import ./kb-globals.nix { inherit pkgs lib config; };
  hyprland-attrs = import ./hyprland.nix { inherit pkgs lib config; };
  ui-config = import ./ui-config.nix { inherit pkgs lib config; };
  attrs = lib.custom.mkHomeApplication {
    #stylix.targets.hyprland.enable = false;
    name = "hyprland";
    packages =
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
    wayland.windowManager.hyprland = lib.mkMerge [
      {
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      }
      {
        plugins = [
          (lib.mkIf config.hl-plugins.hy3.enable inputs.hy3.packages.${pkgs.system}.hy3)
          (lib.mkIf config.hl-plugins.hyprsplit.enable inputs.hyprsplit.packages.${pkgs.system}.hyprsplit)
        ];
      }
      hyprland-attrs.attrs
      { inherit (modesetting.attrs) extraConfig; }
      { inherit (ui-config.hyprland) extraConfig settings; }
    ];
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
    home.sessionVariables = {
      AQ_DRM_DEVICES = "/dev/dri/card1"; # "/dev/dri/by-path/pci-0000:07:00.0-card"
      HL_RESIZE = 100;
      HL_MOVE = 100;
    };
    inherit config;
    inherit extraOptions;
  };
  extraOptions =
    {
      hl-plugins = {
        hy3 = {
          enable = lib.mkEnableOption "Enable hy3.";
        };
        hyprsplit = {
          enable = lib.mkEnableOption "Enable hyprsplit.";
        };
      };
    }
    // kb-globals.options
    // modesetting.options;
in
{
  inherit (attrs) options config;
}

#plugins =
#let
#  hyprsplit = inputs.hyprsplit.packages.${pkgs.system}.hyprsplit.overrideAttrs (oldAttrs: {
#    pkgs.stdenv = inputs.hyprland.packages.${pkgs.system}.default.stdenv;
#  });
#in
#[
#  hyprsplit
#];
