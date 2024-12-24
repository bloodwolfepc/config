{ inputs, pkgs, config, lib, ... }: {
  imports =
    [       
      #TODO nixos hardware modules
      ./hardware-configuration.nix
      #./syncthing.nix
      ./borg.nix
      ../modules/preset/server.nix
      ../modules/users/bloodwolfe
      
      ../modules/server/minecraft
      ./ddns.nix
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
    #firewall = {
    #  enable = true;
    #  interfaces."br0" = {
    #    allowedTCPPorts = [ 80 ];
    #  };
    #};
    nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "br0";
    };
  }; 
  services.resolved.enable = true;
}
  #networking = {
  #  hostName = "navi";
  #  useDHCP = lib.mkForce false;
  #  defaultGateway = {
  #    address = "10.10.0.1";
  #    interface = "eno1";
  #  };
  #  nameservers = [ "10.10.0.1" ];
  #  domain = "navi.loveless.net";
  #  search = [ "navi.loveless.net" ];
  #  interfaces = {
  #    "eno1".ipv4.addresses = [{
  #      address = "10.10.0.2";
  #      prefixLength = 24;
  #    }];
  #    #"vi0".ipv4.addresses = [{
  #    #  virtual = true;
  #    #  address = "10.10.0.11";
  #    #  prefixLength = 16;
  #    #}];
  #    #"vi1".ipv4.addresses = [{
  #    #  virtual = true;
  #    #  address = "10.11.0.1";
  #    #  prefixLength = 16;
  #    #}];
  #    "br0".ipv4.addresses = [{
  #      address = "10.10.0.3";
  #      prefixLength = 24;
  #    }]; 
  #    #"vlan0".ipv4.addresses = [{
  #    #  address = "10.12.0.1";
  #    #  prefixLength = 24;
  #    #}];
  #    #"vlan1".ipv4.addresses = [{
  #    #  address = "10.12.1.1";
  #    #  prefixLength = 24;
  #    #}];
  #  };
  #  #nat = {
  #  #  enable = true;
  #  #  enableIPv6 = true;
  #  #  internalInterfaces = [ "ve-+" ];
  #  #  externalInterfaces = "vlan1";
  #  #};
  #  bridges = {
  #    "br0" = {
  #      interfaces = [ "eno1" ];
  #    };
  #  };
  #  #vlans = {
  #  #  vlan2 = {
  #  #    id = 2;
  #  #    interface = "vi0";
  #  #  };
  #  #  vlan3 = {
  #  #    id = 3;
  #  #    interface = "vi0";
  #  #  };
  #  #};
  #};
#}

