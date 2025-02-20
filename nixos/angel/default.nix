{ config, inputs, pkgs, lib, ... }: {
  imports = [       
    inputs.hardware.nixosModules.asus-zephyrus-ga402
    ./hardware-configuration.nix
    ./monitors.nix
    ../modules/users/bloodwolfe
    ../modules/preset/main.nix
    ../modules/hardware/behringer-404-hd
    ../modules/hardware/gpu-passthrough.nix
    ../modules/hardware/rog-zypherus-g14.nix
    ./passthough
    #./powersave
    ./nonspecial.nix
  ];
  networking.hostName = "angel";
  services.resolved.enable = true;

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    vaapiVdpau
    libvdpau-va-gl
  ];

  #android
  programs.adb.enable = true;
  environment.systemPackages = [ 
    pkgs.universal-android-debloater 
  ];
  users.users.bloodwolfe.extraGroups = ["adbusers"];      
  programs.nix-ld.enable = true;

  specialisation.vfio-passthough.configuration = {
    bwcfg.angel.gpu-detatched.enable = true;
    bwcfg.angel.vfio-passthough.enable = true;
  };
  specialisation.networkmanager.configuration = {
    networking.networkmanager.enable = lib.mkForce true;
    networking.useDHCP = lib.mkForce false;
  };
  specialisation.nmvfio.configuration = {
    bwcfg.angel.gpu-detatched.enable = true;
    bwcfg.angel.vfio-passthough.enable = true;
    networking.networkmanager.enable = lib.mkForce true;
    networking.useDHCP = lib.mkForce false;
  };
  systemd.services.supergfxd.path = [ pkgs.pciutils ];
  services.supergfxd = {
    enable = true;
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
}
