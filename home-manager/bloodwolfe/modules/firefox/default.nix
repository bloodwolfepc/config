#TODO bookmark managerment: flocus, nextcloudbookmarks, linkding
{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "firefox";
    key = "f";
    command = "${pkgs.firefox}/bin/firefox";
    persistDirs = [
      ".mozilla"
      ".cache/mozilla"
    ];
    programs.firefox.enable = true;
    xdg.mimeApps.defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };
    stylix.targets.firefox.enable = false;
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
