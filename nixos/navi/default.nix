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
    ./kopia.nix
    ./openbao-unseal.nix
    ../modules/users/bloodwolfe
    ../modules/impermanence
    ../modules/nix.nix
    ../modules/security.nix
    ../modules/virtualisation.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  sops.defaultSopsFile = "${inputs.secrets}/sops/hosts/navi/system.yaml";

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
      extraCommands = ''
        iptables -A nixos-fw -s 192.168.5.3/32 -p tcp --dport 2049 -j nixos-fw-accept
      '';
      allowedTCPPorts = [
        22
        4533 # Steam
        51821 # Wireguard
        27015 # CS2 remains on navi
        27020 # CS2 remains on navi
      ];
      allowedUDPPorts = [
        51820 # Wireguard
        27015 # CS2 remains on navi
        27020 # CS2 remains on navi
      ];
    };
  };
  services = {
    resolved.enable = true;
    nfs.server = {
      enable = true;
      exports = ''
        /data/storage 192.168.5.3(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=100,fsid=0)
      '';
    };
  };
  systemd.tmpfiles.rules = [
    "d /data/storage 0750 bloodwolfe users -"
    "d /data/storage/library 0755 bloodwolfe users -"
    "d /data/storage/nextcloud 0750 bloodwolfe users -"
    "f /data/storage/.srv-storage 0644 root root - navi-storage"
  ];
  hardware.raid.HPSmartArray.enable = true;

  sops.secrets = {
    "ddnssecret" = { };
  };

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domains = [ "@" ];

    username = "tinywolfe.net";
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
