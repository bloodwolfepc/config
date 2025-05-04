{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "ascii-rain";
  name = pname;
  nativeBuildInputs = with pkgs; [
    gcc
    ncurses
  ];
  src = pkgs.fetchFromGitHub {
    owner = "nkleemann";
    repo = pname;
    rev = "master";
    hash = "sha256-yYZpEevwPppMe9FOZGt5vDkhaeu3zhd2xZycGnT85jI=";
  };
  meta = {
    description = "ncurses rain effect";
    homepage = "https://github.com/nkleemann/ascii-rain";
    license = lib.licenses.mit;
    maintainers = [ "bloodwolfepc" ];
  };
  buildPhase = ''
    gcc rain.c -o rain -lncurses
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp rain $out/bin/ascii-rain
  '';
  patches = [ ./rain.patch ];
}
