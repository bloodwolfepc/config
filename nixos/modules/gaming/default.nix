{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "gaming";
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
      ];
    }; 
    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          softrealtime = "on";
          inhibit_screensave = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-resposibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
  imports = [ inputs.nix-gaming.nixosModules.platformOptimizations ];
}
