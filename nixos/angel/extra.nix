{ pkgs, lib, ... }:
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
  environment.persistence."/persist/system".directories = [
    {
      directory = "/var/lib/colord";
      user = "colord";
      group = "colord";
      mode = "u=rwx,g=rx,o=";
    }
  ];
  i18n = {
    defaultlocale = lib.mkdefault "en_us.utf-8";
    supportedlocales = [
      "en_us.utf-8/utf-8"
      "ja_jp.utf-8/utf-8"
      "ko_kr.utf-8/utf-8"
    ];
  };
  time.timezone = lib.mkdefault "america/chicago";

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
