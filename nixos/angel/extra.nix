{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  hardware.wooting.enable = true;
  hardware.bluetooth.enable = true;
  services.colord.enable = false;
  services.flatpak.enable = true;
  services.udev.packages = [ pkgs.wooting-udev-rules ];
  programs.adb.enable = true;
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

  networking = {
    networkmanager = {
      enable = true;
      unmanaged = [ "interface-name:ve-*" ];
    };
    useDHCP = lib.mkForce false;
  };
  services.resolved.enable = true;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  systemd.services.NetworkManager-wait-online.wantedBy = lib.mkForce [ ];
  services.journald.extraConfig = "SystemMaxUse=50M";
}
