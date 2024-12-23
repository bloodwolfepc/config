{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "ssh";
    programs.ssh = { 
      enable = true;
    };
    sops.secrets."ssh-angel" = {
      path = "/home/bloodwolfe/.ssh/id_ed25519";
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
