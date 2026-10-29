{ pkgs, ... }:
let
  version = "0.1.1";
  piContextAnalyzer = pkgs.buildPiPackage {
    pname = "pi-context-analyzer";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/pi-context-analyzer/-/pi-context-analyzer-${version}.tgz";
      hash = "sha256-MUA8rfWtSU2mks81eyD/zowsVfn22SKULIm082Jqt8A=";
    };
    dontNpmInstall = true;
  };
in
{
  home.file.".pi/agent/nix-packages/pi-context-analyzer".source = piContextAnalyzer;
}
