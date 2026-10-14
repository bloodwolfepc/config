{ config, ... }:
{
  xdg.configFile = {
    "pipewire/pipewire.conf.d/10-low-latency.conf".source =
      config.dotfiles.source "audio/pipewire/10-low-latency.conf" ./pipewire/10-low-latency.conf;
    "pipewire/jack.conf.d/10-low-latency.conf".source =
      config.dotfiles.source "audio/pipewire/10-jack-low-latency.conf" ./pipewire/10-jack-low-latency.conf;
    "wireplumber/wireplumber.conf.d/20-umc-low-latency.conf".source =
      config.dotfiles.source "audio/wireplumber/20-umc-low-latency.conf" ./wireplumber/20-umc-low-latency.conf;
  };
}
