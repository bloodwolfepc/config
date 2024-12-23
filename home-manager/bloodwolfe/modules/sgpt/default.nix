{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "sgpt";
    packages = with pkgs; [
      shell-gpt
    ];
    sops.secrets."sgpt-config" = {
      path = "/home/bloodwolfe/.config/shell_gpt/.sgptrc";
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
