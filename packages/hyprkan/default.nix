# https://github.com/j-ace-svg/nixos-config/blob/d81cd3507bbdb5512753157e0532f073e13b0e9a/nixos/hosts/jane/kanata/hyprkan.nix
{
  lib,
  fetchFromGitHub,
  buildPythonApplication,
  i3ipc,
}:
buildPythonApplication rec {
  pname = "hyprkan";
  version = "2.1.0";
  pyproject = false;

  src = fetchFromGitHub {
    inherit pname version;
    owner = "j-ace-svg";
    repo = "hyprkan";
    rev = "4f12126a5f6c2c466027fa1011447d99d8d5173f";
    hash = "sha256-4ReaXeafUfFR9YAVkRMZTcVFjgRwOgUGoffeYBdyQMA=";
  };

  dontUnpack = true;
  installPhase = ''
    install -Dm755 "$src/src/${pname}.py" "$out/bin/${pname}"
  '';

  propagatedBuildInputs = [
    i3ipc
  ];
  meta = with lib; {
    description = "App-aware Kanata layer switcher for Linux";
    homepage = "https://github.com/mdSlash/hyprkan";
    license = licenses.mit;
  };
}
