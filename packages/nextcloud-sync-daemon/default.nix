{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "nextcloud-sync-daemon";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "graemejross";
    repo = "nextcloud-sync-daemon";
    rev = "v${version}";
    hash = "sha256-XdxnMilPypL2Qave7pNt0ZPQCoiNqD3ZnOpQ/O12wJw=";
  };

  vendorHash = "sha256-meDSMqwlTvaxyeXxCKu8+RiGvfWXGuDIhqPFX/eXdL0=";
  subPackages = [ "cmd/nextcloud-sync-daemon" ];

  meta = {
    description = "Event-driven sync daemon for headless Nextcloud clients";
    homepage = "https://github.com/graemejross/nextcloud-sync-daemon";
    license = lib.licenses.mit;
    mainProgram = "nextcloud-sync-daemon";
    platforms = lib.platforms.linux;
  };
}
