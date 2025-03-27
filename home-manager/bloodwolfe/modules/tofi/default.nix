{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "tofi";
    pcExtraConfig = ''
      submap = NML
        bindi = , SPACE, exec, ${pkgs.tofi}/bin/tofi-drun --drun-launch=true --font ${pkgs.unscii}/share/fonts/opentype/unscii-16-full.otf
      submap = escape
    '';
    programs.tofi = {
      enable = true;
    };
    stylix.targets.tofi.enable = false;
    xdg.configFile."tofi/config".text = lib.mkForce (builtins.readFile ./config.ini); 
    inherit config;
  };
in {
  inherit (attrs) options config;
}
