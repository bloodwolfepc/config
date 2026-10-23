{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  provider = import ./provider.nix;
in
{
  imports = [
    ./disk.nix
    ./impermanence.nix
    ./mail.nix
    ./recovery.nix
    ./wireguard.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking = {
    hostName = "main-vps";
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = lib.optionals provider.bootstrapPublicSsh [ 22 ];
      interfaces.tailscale0.allowedTCPPorts = [ 22 ];
      checkReversePath = "loose";
    };
  };

  systemd.network = {
    enable = true;
    networks."10-uplink" = {
      matchConfig.Name = provider.uplinkMatch;
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
    };
  };

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "sr_mod"
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];
    kernelParams = [ "console=ttyS0,115200n8" ];
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = false;
      hostKeys = [
        {
          path = "/persist/system/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          bits = 4096;
          path = "/persist/system/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
      ];
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    qemuGuest.enable = true;
    tailscale.enable = true;
    journald.settings.Journal.SystemMaxUse = "100M";
  };

  users = {
    mutableUsers = false;
    users.bloodwolfe = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../modules/users/bloodwolfe/id_angel.pub)
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  sops = {
    defaultSopsFormat = "yaml";
    age = {
      generateKey = true;
      keyFile = "/persist/system/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/persist/system/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    btop
    curl
    dig
    gitMinimal
    jq
    podman-compose
    restic
    tmux
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";
}
