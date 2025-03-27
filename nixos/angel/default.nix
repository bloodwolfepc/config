{ config, inputs, pkgs, lib, ... }: {
  imports = [       
    inputs.hardware.nixosModules.asus-zephyrus-ga402
    ./hardware-configuration.nix
    ./monitors.nix
    ./passthough
    ../setup
  ];
  
  config = let
    inherit (config.sysglobals.list)
      require-nixos
      require-pc
      srv-progs
      used-progs
      gaming-progs
    ;
    enable = {
      list = [ 
        "bloodwolfe"
        "zen-kernel"
        "audio"
        "systemd-boot"
      ]
        ++ require-nixos
        ++ require-pc
        ++ srv-progs
        ++ used-progs
        ++ gaming-progs
      ;
      value = {
        enable = true;
        persist.enable = true;
      };
    };
    configured = lib.listToAttrs (map (name: {
      inherit name;
      inherit (enable) value;
    }) enable.list );
  in {
    inherit configured;
    networking.hostName = "angel";
    services.resolved.enable = true;
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    environment.systemPackages = with pkgs; [ 
      powertop
      asusctl
    ];
    programs.nix-ld.enable = true;

    specialisation.vfio-passthough.configuration = {
      configured = {
        angel = {
          gpu-detatched.enable = true;
          vfio-passthough.enable = true;
        };
      };
    };
    specialisation.networkmanager.configuration = {
      configured.networkmanager.enable = true;
    };
    specialisation.nmvfio.configuration = {
      configured = {
        angel = {
          gpu-detatched.enable = true;
          vfio-passthough.enable = true;
        };
        networkmanager.enable = true;
      };
    };

    #systemd.services.supergfxd.path = [ pkgs.pciutils ];
    services.supergfxd = {
      enable = true;
      #path = with pkgs; [ pciutils ];
      settings = lib.mkDefault {
        mode = "Hybrid";
        vfio_enable = true;
        vfio_save = true;
        always_reboot = false;
        no_logind = false;
        logout_timeout_s = 180;
        hotplug_type = "None";
      };
    };
    powerManagement.powertop.enable = true;
    services.asusd = {
      enable = true;
      enableUserService = true;
    };
    #services.switcherooControl.enable = true;
    services.power-profiles-daemon.enable = true;
    programs.rog-control-center.enable = true;
  };
}
