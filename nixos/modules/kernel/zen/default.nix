{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "zen-kernel";
    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      extraModulePackages = with pkgs; [
        linuxKernel.packages.linux_zen.v4l2loopback 
      ];
      kernelModules = [ 
        "v4l2loopback" 
      ];
      kernelParams = [
        "usbcore.autosuspend=-1"
      ];
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
