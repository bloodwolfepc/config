{ pkgs, ... }:
let
  version = "2.0.0";
  piNotify = pkgs.buildPiPackage {
    pname = "pi-notify";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@jmcombs/pi-notify/-/pi-notify-${version}.tgz";
      hash = "sha256-MGyAKnXvxi6QrH7hifLx4eaD31ygETrhnG9TXcFSHUU=";
    };
    dontNpmInstall = true;
  };
in
{
  home.file.".pi/agent/nix-packages/pi-notify".source = piNotify;
}
