{ inputs, outputs }:
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
      system = final.system;
      config.allowUnfree = true;
    };
  };
  modifications = final: prev: {
    supergfxcl = prev.supergfxcl.overrideAttrs (oldAttrs: {
    });
    #install with freedesktop sound theme

    #mesa = prev.mesa.overrideAttrs (oldAttrs: rec {
    #  version = "24.2.8";
    #  src = final.fetchFromGitLab {
    #    domain = "gitlab.freedesktop.org";
    #    owner = "mesa";
    #    repo = "mesa";
    #    rev = "mesa-${version}";
    #    hash = "sha256-70X0Ba7t8l9Vs/w/3dd4UpTR7woIvd7NRwO/ph2rKu8=";
    #  };
    #});

    qt6Packages = prev.qt6Packages.overrideScope (
      _: kprev: {
        qt6gtk2 = kprev.qt6gtk2.overrideAttrs (_: {
          version = "0.5-unstable-2025-03-04";
          src = final.fetchFromGitLab {
            domain = "opencode.net";
            owner = "trialuser";
            repo = "qt6gtk2";
            rev = "d7c14bec2c7a3d2a37cde60ec059fc0ed4efee67";
            hash = "sha256-6xD0lBiGWC3PXFyM2JW16/sDwicw4kWSCnjnNwUT4PI=";
          };
        });
      }
    );

    openpomodoro-cli = prev.openpomodoro-cli.overrideAttrs (oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "linus-witte";
        repo = "openpomodoro-cli";
        rev = "f3d838e5c9aa227cdaf7989d34966e9766c87103";
        sha256 = "sha256-6IEgBmPBbUZLSIzrmBRXYskzpkj8dqEZOz2ghUJMf1A=";
      };
      vendorHash = "sha256-TSWocmOmg5ghudfJsl2bXy3E4P6htp+Bedq0zpLauvU=";
    });

    #needs wayland deps
    # gpu-screen-recorder = prev.gpu-screen-recorder.overrideAttrs (oldAttrs: {
    #   version = "5.5.3";
    #   src = final.fetchurl {
    #     url = oldAttrs.src.url;
    #     hash = "sha256-GzwDKxX5pFSDQ/P0sHFcSUOd2J+od15p/+0iQAs5Yc8=";
    #   };
    # });
    # gpu-screen-recorder-gtk = prev.gpu-screen-recorder-gtk.overrideAttrs (oldAttrs: {
    #   version = "5.7.0";
    #   src = final.fetchurl {
    #     url = oldAttrs.src.url;
    #     hash = "sha256-H2Vx1UyhYi4yk3xd0TW5IKVz+3FdS7g88Zw2W4NBbFo=";
    #   };
    # });

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
  };
}
