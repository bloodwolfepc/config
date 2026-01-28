{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuraion.nix
    ./audio
    ./power
    ./networking
    ../modules
    ../modules/users/bloodwolfe
    inputs.hardware.nixosModules.asus-zephyrus-ga402
  ];

  networking.hostName = "angel";

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    switcherooControl.enable = true;
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
  programs.rog-control-center.enable = true;
  programs.gpu-screen-recorder.enable = true;
  hardware.wooting.enable = true;
  hardware.bluetooth.enable = true;
  services.colord.enable = false;
  services.flatpak.enable = true;
  services.udev.packages = [ pkgs.wooting-udev-rules ];
  programs.kdeconnect.enable = true;
  environment.systemPackages = with pkgs; [
    universal-android-debloater
    displaycal
    wootility
  ];
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    extraLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
      "ko_KR.UTF-8/UTF-8"
    ];
  };
  time.timeZone = lib.mkDefault "America/Chicago";
}
