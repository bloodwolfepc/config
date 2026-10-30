{ pkgs, ... }:
let
  piClaudeBridge = pkgs.buildPiPackage {
    pname = "pi-claude-bridge";
    version = "0.6.3";
    src = pkgs.fetchFromGitHub {
      owner = "elidickinson";
      repo = "pi-claude-bridge";
      rev = "066767393a0efe4be09632f63dc046c2190231b7";
      hash = "sha256-vn2geva8IVwR+sloFp+wUt1f16iGVs10vIn2PAtCSWk=";
    };
    npmDepsHash = "sha256-dRg+b3wOWwYiro+E6hzRc+uefHfNPu2xMiavu+yQKyk=";
    installPhase = ''
      mkdir -p "$out"
      cp -r . "$out/"
      ${pkgs.lib.getExe pkgs.jq} '
        .peerDependencies.typebox = "*"
        | .peerDependencies."@earendil-works/pi-ai" = "*"
        | .peerDependencies."@earendil-works/pi-coding-agent" = "*"
        | .peerDependencies."@earendil-works/pi-tui" = "*"
        | del(.dependencies.typebox)
      ' "$out/package.json" > package.json.tmp
      mv package.json.tmp "$out/package.json"
      rm -rf "$out/node_modules/typebox"
    '';
  };
in
{
  home.file.".pi/agent/nix-packages/pi-claude-bridge".source = piClaudeBridge;
}
