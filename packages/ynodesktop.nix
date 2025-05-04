{
  lib,
  stdenv,
  fetchFromGitHub,
  yarn2nix,
}:

stdenv.mkDerivation rec {
  pname = "ynodesktop";
  version = "1.1.3";
  src = fetchFromGitHub {
    owner = "GummyLeeches";
    repo = "ynodeskitop-linux-binaries";
    rev = "v${version}";
    sha256 = lib.fakeSha256;
  };
  buildInputs = [ yarn2nix ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin 
    cp icat $out/bin 
    runHook postInstall 
  '';
}

#on ynodesktop
#yarn install
#electron run .
