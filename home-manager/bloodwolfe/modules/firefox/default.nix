#TODO bookmark managerment: flocus, nextcloudbookmarks, linkding
{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "firefox";
    key = "f";
    command = "${pkgs.firefox}/bin/firefox";
    pcExecOnce = [
      #TODO: neeeds focus correct monitor first or binds to move workspace to monitors
      #"hyprctl dispatch workspace name:firefox"
    ];
    persistDirs = [
      ".mozilla"
      ".cache/mozilla"
    ];
    programs.firefox.enable = true;
    xdg.mimeApps.defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}



 
