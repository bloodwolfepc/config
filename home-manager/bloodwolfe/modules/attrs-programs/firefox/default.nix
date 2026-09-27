{
  config,
  pkgs,
  ...
}:
{
  home.persistence."/persist".directories = [
    ".mozilla"
    ".cache/mozilla"
    ".config/mozilla"
  ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    # Enables Tridactyl reading from fs using :source
    # Loads a minifest for a helper, where the extension can talk to lock executables on the system, communication handled over stdio json
    nativeMessagingHosts = [ pkgs.tridactyl-native ];
  };

  xdg.configFile."tridactyl".source =
    config.dotfiles.source "attrs-programs/firefox/tridactyl" ./tridactyl;

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
