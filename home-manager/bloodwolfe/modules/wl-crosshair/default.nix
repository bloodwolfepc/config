{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "wl-crosshair";
    packages = [
      #TODO use pkgsFor system
      inputs.wl-crosshair.packages.x86_64-linux.default
    ];
    pcExtraConfig = ''
      submap = TOGGLE
        bindi = , c , exec , wl-crosshair $FLAKE/assets/crosshairs/crosshair.png
        bindi = , v , exec , pkill .wl-crosshair-w
      submap = escape
    '';
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
