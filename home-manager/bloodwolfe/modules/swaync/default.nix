{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "swaync";
    services.swaync = {
      enable = true;
      #settings = { }; #TODO style
      #style = { };
    };
    pcExtraConfig = ''
      submap = NML 
        bindi = , n, exec, swaync-client -t
      submap = escape
    '';
    inherit config;
  };
in {
  inherit (attrs) options config;
}
