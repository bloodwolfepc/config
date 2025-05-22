{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkgs,
}:

rustPlatform.buildRustPackage rec {
  pname = "rbxmidi";
  name = pname;

  src = fetchFromGitHub {
    owner = "Interfiber";
    repo = "rbxmidi";
    rev = "main";
    hash = "sha256-Gvpa9F0ruEHO7Ldx0GOL70QzspGkWiG+eWjeA3qBUok=";
  };

  cargoHash = "sha256-Uoo6/+EuAHISKx/Dg74Z2B3g2RnOEGMQvhBWSEu1zpM=";

  nativeBuildInputs = with pkgs; [
    cargo
    rustc
    pkg-config
    makeWrapper
  ];

  buildInputs = with pkgs; [
    alsa-lib
    xdotool
    wayland

    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libxcb
    libxkbcommon
    libGL
    vulkan-headers
    vulkan-loader
  ];

  postFixup = ''
    wrapProgram $out/bin/${pname} \
      --suffix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs} \
      --suffix WINIT_UNIX_BACKEND : "wayland"
  '';

  meta = {
    description = "Play roblox pianos with a MIDI keybaord";
    homepage = "https://github.com/Interfiber/rbxmidi";
    maintainers = [ "bloodwolfepc" ];
  };
}
