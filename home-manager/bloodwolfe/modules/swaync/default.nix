{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "swaync";
    stylix.targets.swaync.enable = false;
    services.swaync = {
      enable = true;
      settings = {
        control-center-margin-top = 10;
        control-center-margin-bottom = 30;
        control-center-margin-left = 10;
        control-center-margin-right = 10;
        notification-2fa-action = true;
        notification-inline-replies = true;
        widgets = [
          "title"
          "inhibitors"
          "dnd"
          "notifications"
          "mpris"
        ];   
        widget-config = { 
          inhibitors = {
            text = "Inhibitors";
            button-text = ":3";
            clear-all-button = true;
          };
          title = {
            text = "Notifications";
            button-text = ":3";
            clear-all-button = true;
          };
          dnd = {
            text = "quiet";
          };
          label = {
            max-lines = 12;
            text = "sample text";
          };
          mpris = {
            image-size = 96;
            blur = false;
          };
        };
      };
      style = ./style.css;
    };
    pcExtraConfig = ''
      submap = NML 
        bindi = , n, exec, swaync-client -t
      submap = escape
    '';
    inherit config;
  };
in {
  inherit (attrs) options config;
}
