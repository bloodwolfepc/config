{ lib, config }: {
  custom = import ./custom.nix { inherit lib config; };
  minecraft = import ./minecraft.nix { inherit lib; };
}


#let
#  inherit (import ./fixed-points.nix { inherit lib; }) makeExtensible;
#  lib = makeExtensible (self: let
#    callLibs = file: import file { lib = self; };
#  in { 
#    custom = callLibs ./custom.nix { inherit lib; };
#  });
#in lib
