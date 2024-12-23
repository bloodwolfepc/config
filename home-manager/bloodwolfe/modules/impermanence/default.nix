{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "impermanence";
    home = { 
      persistence = {
        "/sync/home/bloodwolfe" = {
          allowOther = true;
        };
        "/persist/home/bloodwolfe" = {
          allowOther = true;
        };
      };
    };
    inherit config;
  }; 
in {
  inherit (attrs) options config;
	imports = [
		inputs.impermanence.nixosModules.home-manager.impermanence
	];
}
