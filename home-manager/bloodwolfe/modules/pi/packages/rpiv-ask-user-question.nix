{ pkgs, ... }:
let
  version = "2.4.0";
  rpivAskUserQuestion = pkgs.buildPiPackage {
    pname = "rpiv-ask-user-question";
    inherit version;
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@juicesharp/rpiv-ask-user-question/-/rpiv-ask-user-question-${version}.tgz";
      hash = "sha256-/NCFHdZ85TMzRIZs4QaMEVONzREPyo/XYWyvzbYneF0=";
    };
    prePatch = ''
      ${pkgs.lib.getExe pkgs.jq} 'del(.devDependencies)' package.json > package.json.tmp
      mv package.json.tmp package.json
      cp ${./locks/rpiv-ask-user-question.json} package-lock.json
    '';
    npmInstallFlags = [
      "--omit=dev"
      "--omit=peer"
      "--legacy-peer-deps"
    ];
    npmDepsHash = "sha256-71k85XYwT+1LluE9Mm+PyDdupZyoAKSWIzaOCll5K90=";
    installPhase = ''
      mkdir -p "$out"
      cp -r . "$out/"
      for manifest in "$out/package.json" "$out/node_modules/@juicesharp/rpiv-config/package.json"; do
        ${pkgs.lib.getExe pkgs.jq} \
          '.peerDependencies.typebox = "*" | del(.dependencies.typebox)' \
          "$manifest" > "$manifest.tmp"
        mv "$manifest.tmp" "$manifest"
      done
      rm -rf "$out/node_modules/typebox"
    '';
  };
in
{
  home.file.".pi/agent/nix-packages/rpiv-ask-user-question".source = rpivAskUserQuestion;
}
