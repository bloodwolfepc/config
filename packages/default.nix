{
  pkgs ? import <nixpkgs>,
}:
rec {
  crossover = pkgs.callPackage ./crossover.nix { };
  openutau = pkgs.callPackage ./openutau.nix { };
  bandcamp-dl = pkgs.callPackage ./bandcamp-dl { };
  rbxmidi = pkgs.callPackage ./rbxmidi { };
  hyprfreeze = pkgs.callPackage ./hyprfreeze.nix { };

  #https://github.com/NixOS/nixpkgs/pull/235730/files#diff-4152af3831cc8cf8d7bbd457274b6fe8ae47899b6625f8fdc6cf8f68821e3e82
  durdraw = pkgs.callPackage ./durdraw { inherit ansilove; };
  ansilove = pkgs.callPackage ./durdraw/ansilove.nix { inherit libansilove; };
  libansilove = pkgs.callPackage ./durdraw/libansilove.nix { };

  ascii-rain = pkgs.callPackage ./ascii-rain { };
}
