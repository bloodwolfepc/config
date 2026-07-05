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
          # local-audio-yomichan
        ]
      ))
    ]
    ++ (with outputs.customPackages.${pkgs.system}; [
      repeater
    ]);
  home.persistence = {
    "/persist".directories = [
      ".local/share/Anki2"
      ".local/share/repeater"
    ];
  };
}
