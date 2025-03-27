{ lib, config, pkgs, inputs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "impermanence";
	  fileSystems."/persist".neededForBoot = true;
	  environment.persistence."/persist/system" = {
	  	hideMounts = true;
	  	directories = [
	  	"/etc/nixos"
	  	"/var/log"
	  	"/var/lib/nixos"
	  	"/var/lib/bluetooth"
	  	"/var/lib/systemd/coredump"
	  	"/etc/NetworkManager/system-connections"
        {
          directory = "/var/lib/flatpak";
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];
	  	files = [
	  		"/etc/machine-id"
	  	];
	  };
    boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    inherit config;
  };
in {
  inherit (attrs) options config;
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];
}
