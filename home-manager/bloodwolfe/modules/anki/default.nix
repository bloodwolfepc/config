{ pkgs, outputs, ... }: {
  home.packages =
    with pkgs;
    [
      (anki.withAddons (
        with pkgs.ankiAddons;
        [
          passfail2
          recolor
          review-heatmap
          fsrs4anki-helper
          ajt-card-management
          anki-connect
          (adjust-sound-volume.withConfig {
            config = {
              volume = 0;
            };
          })
          # local-audio-yomichan
        ]
      ))
    ]
    ++ (with outputs.customPackages.${pkgs.stdenv.hostPlatform.system}; [
      repeater
    ]);
  home.backups.anki = {
    paths = [
      ".local/share/Anki2"
      ".config/Anki"
      ".config/Anki2"
    ];
    exclude = [ "**/Anki2/logs" ];
  };
  home.persistence = {
    "/persist".directories = [
      ".local/share/Anki2"
      ".local/share/repeater"
    ];
  };
}
