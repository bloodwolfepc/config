{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "wl-crosshair";
    packages = [
      #TODO: use pkgsFor system
      inputs.wl-crosshair.packages.${pkgs.system}.default
    ];
    pcExtraConfig = ''
      submap = CONFIG
        bindi = , c , exec , wl-crosshair $FLAKE/assets/crosshairs/crosshair.png
        bindi = , v , exec , pkill .wl-crosshair-w
      submap = escape
    '';
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
