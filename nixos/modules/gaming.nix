{
  lib,
  config,
  pkgs,
  ...
}:
{
  hardware.steam-hardware.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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
  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
