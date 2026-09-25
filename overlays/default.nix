{ inputs, outputs, ... }:
let
  addPatches =
    pkg: patches:
    pkg.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ patches;
    });
in
{

  additions = final: _prev: import ../packages { pkgs = final; };
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  modifications = final: prev: {

    plasma-overdose-kde-theme = prev.plasma-overdose-kde-theme.overrideAttrs (oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "Notify-ctrl";
        repo = "Plasma-Overdose";
        rev = "bb62af2d30d4e7f44e7b79b700993f05961fd6c4";
        sha256 = "sha256-pphNqlYxkfsQDbH4ZscDNJ4fJNSM/3lGxuCkHL9HgTw=";
      };
      installPhase = ''
        runHook preInstall

        mkdir -p $out/share
        mv colorschemes $out/share/color-schemes
        mv plasma $out/share/plasma

        mkdir -p $out/share/aurorae
        mv aurorae $out/share/aurorae/themes

        mkdir -p $out/share/icons/Plasma-Overdose
        mv cursors/index.theme $out/share/icons/Plasma-Overdose/cursor.theme
        mv cursors/cursors $out/share/icons/Plasma-Overdose/cursors

        mkdir -p $out/share/sounds/Plasma-Overdose
        mv sounds/index.theme $out/share/sounds/Plasma-Overdose/index.theme
        mv sounds/stereo $out/share/sounds/Plasma-Overdose/stereo

        runHook postInstall
      '';
    });

    pi-coding-agent = prev.pi-coding-agent.overrideAttrs (
      finalAttrs: _oldAttrs: {
        version = "0.84.3";
        src = final.fetchFromGitHub {
          owner = "earendil-works";
          repo = "pi";
          tag = "v${finalAttrs.version}";
          hash = "sha256-fC9pKgP2qD61ae5d7iOqP8anl88J1N1Bq8X8+aAjA2A=";
        };
        npmDeps = final.fetchNpmDeps {
          name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
          inherit (finalAttrs) src;
          hash = "sha256-cDx28+c4bwtQpiy5+BCvZhZezoZb4WRqfZj2eoEeMbw=";
        };
        modelData = final.fetchurl {
          url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
          hash = "sha256-nECvL0OVD46U57vNDBs1SPAAly2gDE+5wNBSnU19VDE=";
        };
        preBuild = ''
          mkdir -p packages/ai/src/providers/data
          tar -xzf "$modelData" \
            --strip-components=4 \
            -C packages/ai/src/providers/data \
            package/dist/providers/data

          npx tsgo -p packages/telemetry/tsconfig.build.json
          npx tsgo -p packages/protocol/tsconfig.build.json
          npx tsgo -p packages/client/tsconfig.build.json
        '';
        buildPhase = ''
          runHook preBuild

          npx tsgo -p packages/ai/tsconfig.build.json
          npx tsgo -p packages/tui/tsconfig.build.json
          npx tsgo -p packages/agent/tsconfig.build.json
          npm run build --workspace=packages/coding-agent

          runHook postBuild
        '';
        dontNpmPrune = false;
        preInstall = "";
        postInstall = ''
          local nm="$out/lib/node_modules/pi-monorepo/node_modules"

          for ws in @earendil-works/pi-ai:packages/ai \
                    @earendil-works/pi-agent-core:packages/agent \
                    @earendil-works/pi-client:packages/client \
                    @earendil-works/pi-protocol:packages/protocol \
                    @earendil-works/pi-telemetry:packages/telemetry \
                    @earendil-works/pi-tui:packages/tui; do
            IFS=: read -r pkg src <<< "$ws"
            rm "$nm/$pkg"
            cp -r "$src" "$nm/$pkg"
          done

          find "$nm" -type l -lname '*/packages/*' -delete
          find "$nm/.bin" -xtype l -delete
        ''
        + final.lib.optionalString final.stdenvNoCC.hostPlatform.isDarwin ''
          rm -rf \
            "$nm/@anthropic-ai/sandbox-runtime/dist/vendor/seccomp" \
            "$nm/@anthropic-ai/sandbox-runtime/vendor/seccomp"
        '';
      }
    );

    buildPiPackage =
      let
        inherit (final)
          lib
          buildNpmPackage
          fetchNpmDeps
          jq
          curl
          openssl
          cacert
          stdenvNoCC
          ;
        commonDefaults = {
          pname = "pi-extension";
          version = "unstable";
          installPhase = ''
            mkdir -p $out
            cp -r . $out/
          '';
        };
        # Some pi deps ship without a lockfile integrity field
        # (https://github.com/earendil-works/pi/issues/5653). A single shared
        # placeholder integrity makes every such dep collide on one npm cache
        # entry, so a fetch race decides the winner and the FOD is
        # non-deterministic. Instead fetch each dep's real registry integrity. This
        # runs only inside the FOD, where network is available, and is
        # deterministic because prefetch-npm-deps verifies every tarball against it.
        fetchRealIntegrity = ''
          for url in $(${lib.getExe jq} -r '[.. | objects | select(has("resolved") and (has("integrity") | not)) | .resolved] | unique | .[]' package-lock.json); do
            tarball="$(mktemp)"
            # Download to a file (not a pipe) so a failed fetch aborts the build
            # instead of silently yielding an empty digest; time out and retry so a
            # stalled connection can't hang the build forever.
            ${lib.getExe curl} -sSL --fail --connect-timeout 15 --max-time 300 \
              --retry 5 --retry-all-errors --retry-delay 2 \
              --cacert "${cacert}/etc/ssl/certs/ca-bundle.crt" -o "$tarball" "$url"
            integrity="sha512-$(${lib.getExe openssl} dgst -sha512 -binary "$tarball" | base64 -w0)"
            rm -f "$tarball"
            ${lib.getExe jq} --arg url "$url" --arg integrity "$integrity" \
              '(.. | objects | select(.resolved? == $url and (has("integrity") | not))) |= (. + {integrity: $integrity})' \
              package-lock.json > fixed-package-lock.json
            mv fixed-package-lock.json package-lock.json
          done
        '';
        npmDefaults = commonDefaults // {
          npmInstallFlags = [ "--omit=dev" ];
          npmDepsFetcherVersion = 2;
          dontNpmBuild = true;
        };
      in
      args:
      if args.dontNpmInstall or false then
        stdenvNoCC.mkDerivation (commonDefaults // args)
      else if args ? npmDeps then
        buildNpmPackage (npmDefaults // args)
      else
        let
          npmDeps = fetchNpmDeps {
            inherit (args) src;
            name = "${args.pname or commonDefaults.pname}-${args.version or commonDefaults.version}-npm-deps";
            hash = args.npmDepsHash;
            fetcherVersion = 2;
            nativeBuildInputs = [
              jq
              curl
              openssl
            ];
            # Run any package-specific prePatch (e.g. vendoring a lockfile)
            # before backfilling integrity for deps that still lack it.
            prePatch = (args.prePatch or "") + "\n" + fetchRealIntegrity;
          };
        in
        buildNpmPackage (
          npmDefaults
          // (builtins.removeAttrs args [ "npmDepsHash" ])
          // {
            inherit npmDeps;
            # The main build has no network, so reuse the integrity-patched
            # lockfile the FOD already produced; npmConfigHook requires it to
            # match ${npmDeps}/package-lock.json exactly, and to stay writable
            # for its own --fixup-lockfile pass.
            postPatch = ''
              rm -f package-lock.json
              cp ${npmDeps}/package-lock.json package-lock.json
              chmod u+w package-lock.json
            ''
            + (args.postPatch or "");
          }
        );

    gamescope = prev.gamescope.overrideAttrs (_: {
      NIX_CFLAGS_COMPILE = [ "-fno-fast-math" ];
    });

  };
}
