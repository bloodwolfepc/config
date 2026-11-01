{ pkgs, ... }:
{
  home.persistence = {
    "/persist" = {
      directories = [
        ".config/BeeRef"
        ".config/GIMP"
        ".local/share/krita"
      ];
      files = [
        ".config/kritarc"
        ".config/kritadisplayrc"
      ];
    };
  };
  home.backups.state.paths = [
    "projects/art"
    ".config/GIMP"
    ".local/share/krita"
    ".config/kritarc"
    ".config/kritadisplayrc"
    ".config/BeeRef/BeeRef.ini"
  ];
  home.packages = with pkgs; [
    beeref
    krita
    gimp
  ];
}
