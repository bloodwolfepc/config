{
  #https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#behringer-umc404hd-microphoneguitar-virtual-sources
  #imports = [ ../audio/low-latency-audio ];
  boot.extraModprobeConfig = ''
    options snd slots=snd-usb-audio
  '';
  services.pipewire.extraConfig.pipewire."92-BehringerUMC404HD" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "UMC Speakers";
          "capture.props" = {
            "media.class" = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name" = "playback.UMC_Speakers";
            "audio.position" = [ "AUX0" "AUX1" ];
            "target.object" = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.pro-output-0";
            "stream.dont-remix" = "true";
            "node.passive" = "true";
          };
        };
      } 
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "UMC Headphones";
          "capture.props" = {
            "media.class" = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name" = "playback.UMC_Headphones";
            "audio.position" = [ "AUX2" "AUX3" ];
            "target.object" = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.pro-output-0";
            "stream.dont-remix" = "true";
            "node.passive" = "true";
          };
        };
      }
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.name" = "UMC_Mic";
          "node.description" = "UMC Microphone";
          "capture.props" = {
            "audio.position" = [ "AUX0" ];
            "stream.dont-remix" = true;
            "node.target" = "alsa_input.usb-BEHRINGER_UMC404HD_192k-00.pro-input-0";
            "node.passive" = true;
          };
          "playback.props" = {
            "media.class" = "Audio/Source";
            "audio.position" = [ "MONO" ];
          };
        };
      }
    ];
  };
}
