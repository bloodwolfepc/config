{ inputs, config, pkgs, ... }: {
  imports = [  
	  inputs.hardware.nixosModules.common-cpu-intel
	  inputs.hardware.nixosModules.common-gpu-amd
    ./hardware-configuration.nix
    inputs.disko.nixosModules.default
    ( import ../modules/option/disc/impermanence-btrfs.nix { device = "/dev/nvme0n1"; })
    ../modules/option/impermanence/impermanence-btrfs.nix
    ../modules/option/spec/openrgb.nix

    ../../hardware/behringer-404-hd.nix
    ../modules/option/audio/musnix.nix
    ../modules/option/audio/low-latency-audio.nix
    
    ../modules/require

    ../modules/preset/full-system.nix

    ../modules/users/bloodwolfe


    ../modules/option/gui/wine.nix
    #../modules/option/virtualization/docker.nix

    ../modules/option/theme/stylix.nix
  ];
  programs.kdeconnect.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    hostName = "lapis";
    useDHCP = true;
    defaultGateway = {
      address = "192.168.0.1";
      interface = "enp6s0";
    };
    interfaces = {
      enp6s0 = {
        #ipv4.addresses = [
        #  {
        #    address = "192.168.0.189"; #189
        #    prefixLength = 24;
        #  }
        #];
        #ipv6.addresses = [
        #  {
        #    address = "2a01:4f8:1c1b:16d0::1";
        #    prefixLength = 64;
        #  }
        #];
      };
    };
    #defaultGateway6 = {
    #  address = "fe80::1";
    #};
  };    
  #sops.secrets."noip-pass" = { };
  #services.ddclient = {
  #  enable = true;
  #  protocol = "duckdns"; 
  #  server = "www.duckdns.org";
  #  domains = [ "bloodwolfe.duckdns.org" ];
  #  use = "web, web=ifconfig.me";
  #  #"cmd, cmd=/persist/duckdns.sh"; 
  #  username = "haschabert@gmail.com";
  #  passwordFile = config.sops.secrets."noip-pass".path;
  #  interval = "300";
  #};
  #hardware.graphics = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    vaapiVdpau
  #    #libvdpau-va-gl 
  #  ];   
  #}; 
  #hardware.amdgpu.initrd.enable = true; #UPDATE
  boot.initrd.kernelModules = [ "amdgpu" ];
  # programs.corectrl = {
  #   enable = true;
  #   gpuOverclock.enable = true;
  # };
  programs.thunar.enable = true;
  services.tumbler.enable = true;
  
  sops.secrets = {
    "syncthing-key-lapis" = {
      owner = "syncthing";
    };
    "syncthing-cert-lapis" = {
      owner = "syncthing";
    };
  };
  services.syncthing = { 
    key = config.sops.secrets."syncthing-key-lapis".path;
    cert = config.sops.secrets."syncthing-cert-lapis".path;
  };
}
