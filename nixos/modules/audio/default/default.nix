{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkConfig {
    name = "audio";
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
