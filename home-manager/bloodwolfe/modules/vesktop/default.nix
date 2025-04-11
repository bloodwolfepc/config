{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "vesktop";
    key = "d";
    command = "${pkgs.vesktop}/bin/vesktop";
    pcWindowRule = [
      "workspace 3 silent, initialClass:^([Vv]esktop)$"
      "workspace 3 silent, initialClass:^([Vv]esktop)$, initialTitle:^([Vv]esktop)$"
    ];
    packages = with pkgs; [
      vesktop
    ];
    persistDirs = [
      ".config/vesktop"
    ];
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
