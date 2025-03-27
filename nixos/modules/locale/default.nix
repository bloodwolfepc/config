{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkConfig {
    name = "locale";
    i18n = {
      defaultLocale = lib.mkDefault "en_US.UTF-8";
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "ja_JP.UTF-8/UTF-8"
        "ko_KR.UTF-8/UTF-8"
      ];
    };
    time.timeZone = lib.mkDefault "America/Chicago";
    inherit config;
  }; 
in {
  inherit (attrs) options config;
}
