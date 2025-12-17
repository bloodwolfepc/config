{ inputs }:
{
  additions = final: _prev: import ../packages { pkgs = final; };
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
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
  };
}
