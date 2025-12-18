{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuraion.nix
    ./audio
    ./extra.nix
    ./vpn.nix
    ../modules
    ../modules/users/bloodwolfe
    inputs.hardware.nixosModules.asus-zephyrus-ga402
    inputs.home-manager.nixosModules.home-manager
  ]
  ++ (builtins.attrValues outputs.myNixosModules);

  networking.hostName = "angel";
  services.resolved.enable = true;
  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    switcherooControl.enable = true;
    power-profiles-daemon.enable = true;
    #services.upower.enable = true;
    auto-cpufreq.enable = false;

    supergfxd = {
      enable = true;
      settings = lib.mkDefault {
        mode = "AsusMuxDgpu";
        vfio_enable = true;
        vfio_save = true;
        always_reboot = false;
        no_logind = false;
        logout_timeout_s = 180;
        hotplug_type = "None";
      };
    };
  };
  programs.rog-control-center.enable = true;
  powerManagement.powertop.enable = true;
  environment.systemPackages = with pkgs; [
    asusctl
    powertop
  ];
  programs.gpu-screen-recorder.enable = true;

  #kernel
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
    extraModulePackages = with pkgs; [
      linuxKernel.packages.linux_zen.v4l2loopback
    ];
    kernelModules = [
      "v4l2loopback"
    ];
    kernelParams = [
      "usbcore.autosuspend=-1"

      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    postBootCommands = ''
      mkdir /mnt
    '';
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };
  hardware.enableRedistributableFirmware = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout = 120
  '';

  system.stateVersion = "23.11";
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.fuse.userAllowOther = true;
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  boot.initrd.postDeviceCommands = lib.mkAfter (builtins.readFile ./ephemeral-btrfs.sh);

  services.udev.extraRules =
    let
      activatePowerSaver = pkgs.writeShellScript "power-save" "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver";
      activatePerformance = pkgs.writeShellScript "performance" "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    in
    ''
      SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${activatePowerSaver}"
      SUBSYSTEM=="power_supply", ATTR{status}=="Charging", RUN+="${activatePerformance}"
      SUBSYSTEM=="power_supply", ATTR{status}=="Full", RUN+="${activatePerformance}"
    '';
}
