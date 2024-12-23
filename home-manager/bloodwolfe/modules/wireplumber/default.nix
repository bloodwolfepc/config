{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "wireplumber";
    persistDirs = [
      ".local/state/wireplumber"
    ];
    #pcExecOnce = [];
      #set wireplumber default sink
      #"wpctl set-default `wpctl status | grep playback.UMC_Headphones | egrep '^ │( )*[0-9]*' -o | cut -c6-55 | egrep -o '[0-9]*'`"
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
