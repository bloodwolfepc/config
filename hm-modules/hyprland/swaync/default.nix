{
  lib,
  config,
  ...
}:
{
  services.swaync = {
    enable = true;
    settings = {
      transition-time = 0;
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
  };
  home.activation.swaync-copy-style-css = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/swaync/style.css" ]; then
      touch "$HOME/.config/swaync/style.css"
      chmod u+w "$HOME/.config/swaync/style.css"
      cp ${./style.css} "$HOME/.config/swaync/style.css"
    fi
  '';
}
