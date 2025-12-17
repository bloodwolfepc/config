{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "qutebrowser";
    command = "${pkgs.qutebrowser}/bin/qutebrowser";
    key = "q";
    syncDirs = [
      ".config/qutebrowser/bookmarks"
      ".local/share/qutebrowser"
    ];
    syncFiles = [
      ".config/qutebrowser/quickmarks"
    ];
    programs.qutebrowser = {
      enable = true;
      loadAutoconfig = true;
      extraConfig = (builtins.readFile ./config.py);
      greasemonkey = [
        #(pkgs.fetchurl {
        #  url = "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_sponsorblock.js";
        #  sha256 = "sha256-e3QgDPa3AOpPyzwvVjPQyEsSUC9goisjBUDMxLwg8ZE=";
        #})
        (pkgs.writeText "darkreader.js" (builtins.readFile ./greasemonkey/darkreader.js))
      ];
      searchEngines = rec {
        k = "https://kagi.com/search?q={}";
        ddg = "https://duckduckgo.com/?q={}";
        g = "https://google.com/search?hl=en&q={}";
        DEFAULT = k;
      };
      settings = {
        url = rec {
          default_page = "https://kagi.com";
          start_pages = [ default_page ];
        };
        downloads.open_dispatcher = "${lib.getExe pkgs.handlr-regex} open {}";
        editor.command = [
          "${lib.getExe pkgs.handlr-regex}"
          "open"
          "{file}"
        ];
        tabs = {
          show = "multiple";
          position = "left";
          indicator.width = 0;
        };
      };
    };
    xdg.mimeApps.defaultApplications = {
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "text/xml" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/qute" = [ "org.qutebrowser.qutebrowser.desktop" ];
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
