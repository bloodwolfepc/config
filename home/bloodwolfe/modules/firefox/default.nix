{ pkgs, lib, inputs, ... }: {
  #TODO bookmark managerment: flocus, nextcloudbookmarks, linkding
  imports = [ ./hyprland.nix ];
  programs.firefox.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = ["firefox.desktop"];
    "text/xml" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];
  };
	home.persistence."/persist/home/bloodwolfe" = {
    directories = [
      ".mozilla"
      ".cache/mozilla"
    ];
  };
 
  #programs.firefox = {
  #  enable = true;
  #  profiles.bloodwolfepc = {
  #    search = {
  #      force = true;
  #      default = "Kagi";
  #      privateDefault = "DuckDuckGo";
  #      order = ["Kagi" "DuckDuckGo" "Google"];
  #      engines = {
  #        "kagi" = {            
  #          urls = [{template = "https://kagi.com/search?q={searchTerms}";}];
  #          iconUpdateURL = "https://kagi.com/favicon.ico";
  #        };
  #        "Bing".metaData.hidden = true;
  #      };
  #    };
  #    #bookmarks = {};
  #    extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
  #      web-scrobbler
  #      ublock-origin
  #      bitwarden
  #      tridactyl
  #      musescore-downloader
  #      kagi-search
  #      darkreader
  #      #enhancer-for-youtube
  #      #violentmonkey
  #      #wayback-machine
  #      
  #      #UNPAKAGED
  #      #volume control for bandcamp
  #      #friends who listen
  #      #oldtwitter
  #    ];
  #    #from https://github.com/Misterio77/nix-config/blob/7ede608b314eb4b59a588e1d7bfc644ccc409e0e/home/gabriel/features/desktop/common/firefox.nix#L7
  #    settings = {
  #      "browser.startup.homepage" = "about:home";

  #      # Disable irritating first-run stuff
  #      "browser.disableResetPrompt" = true;
  #      "browser.download.panel.shown" = true;
  #      "browser.feeds.showFirstRunUI" = false;
  #      "browser.messaging-system.whatsNewPanel.enabled" = false;
  #      "browser.rights.3.shown" = true;
  #      "browser.shell.checkDefaultBrowser" = false;
  #      "browser.shell.defaultBrowserCheckCount" = 1;
  #      "browser.startup.homepage_override.mstone" = "ignore";
  #      "browser.uitour.enabled" = false;
  #      "startup.homepage_override_url" = "";
  #      "trailhead.firstrun.didSeeAboutWelcome" = true;
  #      "browser.bookmarks.restore_default_bookmarks" = false;
  #      "browser.bookmarks.addedImportButton" = true;

  #      # Don't ask for download dir
  #      "browser.download.useDownloadDir" = false;

  #      # Disable crappy home activity stream page
  #      "browser.newtabpage.activity-stream.feeds.topsites" = false;
  #      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  #      "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
  #      "browser.newtabpage.blocked" = lib.genAttrs [
  #        # Youtube
  #        "26UbzFJ7qT9/4DhodHKA1Q=="
  #        # Facebook
  #        "4gPpjkxgZzXPVtuEoAL9Ig=="
  #        # Wikipedia
  #        "eV8/WsSLxHadrTL1gAxhug=="
  #        # Reddit
  #        "gLv0ja2RYVgxKdp0I5qwvA=="
  #        # Amazon
  #        "K00ILysCaEq8+bEqV/3nuw=="
  #        # Twitter
  #        "T9nJot5PurhJSy8n038xGA=="
  #      ] (_: 1);

  #      # Disable some telemetry
  #      "app.shield.optoutstudies.enabled" = false;
  #      "browser.discovery.enabled" = false;
  #      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  #      "browser.newtabpage.activity-stream.telemetry" = false;
  #      "browser.ping-centre.telemetry" = false;
  #      "datareporting.healthreport.service.enabled" = false;
  #      "datareporting.healthreport.uploadEnabled" = false;
  #      "datareporting.policy.dataSubmissionEnabled" = false;
  #      "datareporting.sessions.current.clean" = true;
  #      "devtools.onboarding.telemetry.logged" = false;
  #      "toolkit.telemetry.archive.enabled" = false;
  #      "toolkit.telemetry.bhrPing.enabled" = false;
  #      "toolkit.telemetry.enabled" = false;
  #      "toolkit.telemetry.firstShutdownPing.enabled" = false;
  #      "toolkit.telemetry.hybridContent.enabled" = false;
  #      "toolkit.telemetry.newProfilePing.enabled" = false;
  #      "toolkit.telemetry.prompted" = 2;
  #      "toolkit.telemetry.rejected" = true;
  #      "toolkit.telemetry.reportingpolicy.firstRun" = false;
  #      "toolkit.telemetry.server" = "";
  #      "toolkit.telemetry.shutdownPingSender.enabled" = false;
  #      "toolkit.telemetry.unified" = false;
  #      "toolkit.telemetry.unifiedIsOptIn" = false;
  #      "toolkit.telemetry.updatePing.enabled" = false;

  #      # Disable fx accounts
  #      "identity.fxaccounts.enabled" = false;
  #      # Disable "save password" prompt
  #      "signon.rememberSignons" = false;
  #      # Harden
  #      "privacy.trackingprotection.enabled" = true;
  #      "dom.security.https_only_mode" = true;
  #      # Layout
  #      "browser.uiCustomization.state" = builtins.toJSON {
  #        currentVersion = 20;
  #        newElementCount = 5;
  #        dirtyAreaCache = ["nav-bar" "PersonalToolbar" "toolbar-menubar" "TabsToolbar" "widget-overflow-fixed-list"];
  #        placements = {
  #          PersonalToolbar = ["personal-bookmarks"];
  #          TabsToolbar = ["tabbrowser-tabs" "new-tab-button" "alltabs-button"];
  #          nav-bar = ["back-button" "forward-button" "stop-reload-button" "urlbar-container" "downloads-button" "ublock0_raymondhill_net-browser-action" "_testpilot-containers-browser-action" "reset-pbm-toolbar-button" "unified-extensions-button"];
  #          toolbar-menubar = ["menubar-items"];
  #          unified-extensions-area = [];
  #          widget-overflow-fixed-list = [];
  #        };
  #        seen = ["save-to-pocket-button" "developer-button" "ublock0_raymondhill_net-browser-action" "_testpilot-containers-browser-action"];
  #      };
  #    };
  #  };
  #};
}
