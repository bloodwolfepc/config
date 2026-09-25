{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.srv.homeManagerModules.default
    ../modules/navi.nix
  ];
  dotfiles.mutable = false;

  srv = {
    enable = true;
    servicesPath = "${config.home.homeDirectory}/src/srv/services";
  };
  sops.secrets."PG_PASS" = { };

  programs.zsh.initContent = ''
    export PG_PASS="$(cat ${config.sops.secrets."PG_PASS".path})"
  '';

  sops.secrets."compose-env" = {
    sopsFile = "${inputs.secrets}/secrets/compose.env";
    format = "dotenv";
    path = "${config.home.homeDirectory}/compose.env";
    mode = "0400";
  };
  sops.secrets."compose-auth-env" = {
    sopsFile = "${inputs.secrets}/secrets/compose-auth.env";
    format = "dotenv";
    path = "${config.home.homeDirectory}/compose-auth.env";
    mode = "0400";
  };
  sops.secrets."compose-cs2-env" = {
    sopsFile = "${inputs.secrets}/secrets/compose-cs2.env";
    format = "dotenv";
    path = "${config.home.homeDirectory}/compose-cs2.env";
    mode = "0400";
  };
  home.packages = with pkgs; [
    internetarchive
    (pkgs.writeShellScriptBin "mk-crypt-hash" ''
      set -euo pipefail
      ${pkgs.apacheHttpd}/bin/htpasswd -nbB "" "$1" | cut -d: -f2
    '')
  ];
  # systemd.user.services =
  #   let
  #     srv = pkgs.writeShellScriptBin "srv" ''
  #       set -euo pipefail
  #
  #       compose_files=()
  #
  #       if [ -f .compose-files ]; then
  #         while IFS= read -r line || [ -n "$line" ]; do
  #           case "$line" in
  #             ""|\#*)
  #               continue
  #               ;;
  #           esac
  #           compose_files+=(-f "$line")
  #         done < .compose-files
  #       else
  #         for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
  #           if [ -f "$f" ]; then
  #             compose_files+=(-f "$f")
  #             break
  #           fi
  #         done
  #       fi
  #
  #       if [ "''${#compose_files[@]}" -eq 0 ]; then
  #         echo "no .compose-files and no compose file found in $(pwd)" >&2
  #         exit 1
  #       fi
  #
  #       cmd="''${1:-}"
  #       shift || true
  #
  #       case "$cmd" in
  #         up)
  #           exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" up -d --build --force-recreate "$@"
  #           ;;
  #         down)
  #           exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" down "$@"
  #           ;;
  #         *)
  #           echo "usage: project {up|down}" >&2
  #           exit 1
  #           ;;
  #       esac
  #     '';
  #     mkPodmanService = service: {
  #       "srv-${service}" = {
  #         Install = {
  #           WantedBy = [ "default.target" ];
  #         };
  #         Unit = {
  #           Description = "Run compose files for ${service}";
  #           After = [ "podman.socket" ];
  #           Wants = [ "podman.socket" ];
  #         };
  #         Service = {
  #           Type = "oneshot";
  #           RemainAfterExit = true;
  #           WorkingDirectory = "%h/src/srv/${service}";
  #           ExecStart = "${srv}/bin/srv up";
  #           ExecStop = "${srv}/bin/srv down";
  #           Environment = [
  #             "PATH=/run/wrappers/bin:/home/bloodwolfe/.nix-profile/bin:/run/current-system/sw/bin"
  #           ];
  #         };
  #       };
  #     };
  #   in
  #   lib.mkMerge [
  #     (mkPodmanService "socket")
  #     (mkPodmanService "headscale")
  #     (mkPodmanService "proxy")
  #     (mkPodmanService "auth")
  #     (mkPodmanService "site")
  #     (mkPodmanService "cloud")
  #     (mkPodmanService "film")
  #     (mkPodmanService "music")
  #     (mkPodmanService "library")
  #     (mkPodmanService "audiobooks")
  #     (mkPodmanService "gameyfin")
  #     (mkPodmanService "flame")
  #     (mkPodmanService "arr")
  #   ];
}
