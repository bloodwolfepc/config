{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  hardware.wooting.enable = true;
  hardware.bluetooth.enable = true;
  services.colord.enable = true;
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
    defaultLocale = lib.mkDefault "en_us.utf-8";
    supportedLocales = [
      "en_us.utf-8/utf-8"
      "ja_jp.utf-8/utf-8"
      "ko_kr.utf-8/utf-8"
    ];
  };
  time.timeZone = lib.mkDefault "america/chicago";

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
}
