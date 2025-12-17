{ pkgs, ... }:
{
  imports = [
    ./daw.nix
  ];
  home.persistence = {
    "/sync/home/bloodwolfe" = {
      directories = [
        "olive"

        "beeref"
        ".config/BeeRef"

        "cadfiles"
        ".config/freecad"

        "gimp"
        ".config/GIMP"

        "godot"
        ".config/godot"
        ".local/share/godot"

        "krita"
        ".local/share/krita"
      ];
      files = [
        ".config/kritarc"
        ".config/kritadisplayrc"
      ];
    };
  };
  home.packages = with pkgs; [
    beeref
    krita
    gimp
    olive-editor
    freecad
  ];
}
