{
  rustPlatform,
  lib,
  pkgs,
}:

rustPlatform.buildRustPackage rec {
  pname = "repeater";
  version = "0.1.10";

  src = pkgs.fetchFromGitHub {
    owner = "shaankhosla";
    repo = "repeater";
    rev = "v${version}";
    sha256 = "sha256-8TWqY78w5cOirLnrBONiratAZQSQrYpp++5dXRlFlNo=";
  };

  cargoHash = "sha256-hngZ55o1YsnstBGjp8++9SsxwfUyu+X4YwZuzMupFTE=";

  nativeBuildInputs = with pkgs; [
    pkg-config
    sqlite
    libsecret
    openssl
    dbus
  ];

  buildInputs = with pkgs; [
    sqlite
    libsecret
    openssl
    dbus
  ];

  meta = with lib; {
    description = "Spaced repetition, in your terminal";
    homepage = "https://github.com/shaankhosla/repeater";
    license = licenses.mit;
  };
}
