{ pkgs ? import <nixpkgs> } : rec {
  hello = pkgs.callPackage ./hello.nix { };
  icat = pkgs.callPackage ./icat.nix { };
  crossover = pkgs.callPackage ./crossover.nix { };
  openutau = pkgs.callPackage ./openutau.nix { };
  rofi-pass = pkgs.callPackage ./pass-wofi { };
  #beeref = pkgs.callPackage ./beeref { };
  doukutsu-rs = pkgs.callPackage ./doukutsu-rs { };
  bandcamp-dl = pkgs.callPackage ./bandcamp-dl { };

  #https://github.com/NixOS/nixpkgs/pull/235730/files#diff-4152af3831cc8cf8d7bbd457274b6fe8ae47899b6625f8fdc6cf8f68821e3e82
  durdraw = pkgs.callPackage ./durdraw { inherit ansilove; };
  ansilove = pkgs.callPackage ./durdraw/ansilove.nix { inherit libansilove; };
  libansilove = pkgs.callPackage ./durdraw/libansilove.nix { };


  ascii-rain = pkgs.callPackage ./ascii-rain { };

}
#customPackages = forEachSystem (pkgs: import ./packages { inherit pkgs; });

#systems = [
#  "x86_64-linux"
#];
#lib = nixpkgs.lib // home-manager.lib;
#forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
#pkgsFor = lib.genAttrs systems (system: import nixpkgs {
#	inherit system;
#	config.allowUnfree = true;
#});
