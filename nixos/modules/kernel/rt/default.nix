{ lib, config, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "rt-kernel";
    musnix = {
      kernel.realtime = true;
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
  imports = [ inputs.musnix.nixosModules.default ];
}
