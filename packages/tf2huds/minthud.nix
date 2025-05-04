{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "minthud";
  name = pname;
  src = pkgs.fetchFromGitHub {
    owner = "Mint-tf";
    repo = pname;
    rev = "master";
    hash = lib.fakeHash;
  };
  meta = {
    description = "A simplistic competitive TF2 hud.";
    homepage = "https://github.com/Mint-tf/minthud";
    maintainers = [ "bloodwolfepc" ];
  };
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    mkdir -p $out/share/tf2-huds
    mkdir -p $out/share/tf2-huds/minthud

    mv customisations $out/tf2-huds/minthud
    mv materials $out/tf2-huds/minthud
    mv resouce $out/tf2-huds/minthud
    mv scripts $out/tf2-huds/minthud
    mv info.vfd $out/tf2-huds/minthud

    runHook postInstall
  '';
}
