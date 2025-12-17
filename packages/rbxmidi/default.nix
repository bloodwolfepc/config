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
    #owner = "Interfiber";
    owner = "bloodwolfepc";
    repo = "rbxmidi";
    rev = "fixup";
    hash = "sha256-kbgjiBawIoIfUj/Ig48UdBVUzSrX57wlSGyLQtHEB+0=";
    #hash = "sha256-Gvpa9F0ruEHO7Ldx0GOL70QzspGkWiG+eWjeA3qBUok=";
  };

  #cargoHash = "sha256-Uoo6/+EuAHISKx/Dg74Z2B3g2RnOEGMQvhBWSEu1zpM=";
  cargoHash = "sha256-o3zh7OWaASGr0RbF7QoWM2IL6f1NU8l3vyi6QbvI1VU=";

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
    xdo
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

#- `build-essential`
#- `pkg-config`
#- `libasound2-dev`
#- `libxdo-dev`
