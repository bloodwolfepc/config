{ pkgs, ... }:
{
  imports = [
    ./daw.nix
  ];
  home.persistence = {
    "/persist/home/bloodwolfe" = {
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
  home.packages = with pkgs; [
    beeref
    krita
    gimp
  ];
}
