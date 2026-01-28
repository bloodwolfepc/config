{
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./backups.nix
    ../modules/users/bloodwolfe
    ../modules/impermanence.nix
    ../modules/kanata.nix
    ../modules/nix.nix
    ../modules/security.nix
    ../modules/virtualisation.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  networking = {
    hostName = "navi";
    useDHCP = lib.mkForce false;
    interfaces = {
      "br0" = {
        useDHCP = true;
      };
    };
    bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
    nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "br0";
    };
  };
  services.resolved.enable = true;
  hardware.raid.HPSmartArray.enable = true;

  sops.secrets = {
    "ddnssecret" = { };
  };

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domains = [ "@" ];
    username = "waterdreamer.net";
    passwordFile = config.sops.secrets."ddnssecret".path;
    use = "web ,web=dynamicdns.park-your-domain.com/getip";
    server = "dynamicdns.park-your-domain.com";
  };
}
