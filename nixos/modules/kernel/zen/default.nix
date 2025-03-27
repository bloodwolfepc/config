{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "zen-kernel";
    boot.kernelPackages = pkgs.linuxPackages_zen;
    boot.extraModulePackages = with pkgs; [
      linuxKernel.packages.linux_zen.v4l2loopback 
    ];
    boot.kernelModules = [ 
      "v4l2loopback" 
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
