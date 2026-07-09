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
    ../modules/impermanence
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
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        4533 # Steam
        51821 # Wireguard
        8080
        8443
      ];
      allowedUDPPorts = [
        51820 # Wireguard
        8080
        8443
      ];
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

    server = "dynamicdns.park-your-domain.com";
    usev4 = "webv4, webv4=dynamicdns.park-your-domain.com/getip";
    usev6 = "disabled";
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };

  users.users."bloodwolfe".linger = true;

  services.tailscale.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];
}
