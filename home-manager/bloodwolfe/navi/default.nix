{
  pkgs,
  lib,
  outputs,
  ...
}:
{
  imports = [
    ../../../hm-modules/navi.nix
  ];

  home.packages =
    with pkgs;
    [
      internetarchive
      (writeShellScriptBin "bandcamp-dl-for-navi" ''
        ${outputs.customPackages.x86_64-linux.bandcamp-dl}/bin/bandcamp-dl --base-dir /data/1/library/music -e -r "$@"
      '')
      (pkgs.writeShellScriptBin "mk-crypt-hash" ''
        set -euo pipefail
        ${pkgs.apacheHttpd}/bin/htpasswd -nbB "" "$1" | cut -d: -f2
      '')
    ]
    ++ (with outputs.customPackages.x86_64-linux; [
      bandcamp-dl
    ]);
  systemd.user.services =
    let
      srv = pkgs.writeShellScriptBin "srv" ''
        set -euo pipefail

        compose_files=()

        if [ -f .compose-files ]; then
          while IFS= read -r line || [ -n "$line" ]; do
            case "$line" in
              ""|\#*)
                continue
                ;;
            esac
            compose_files+=(-f "$line")
          done < .compose-files
        else
          for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
            if [ -f "$f" ]; then
              compose_files+=(-f "$f")
              break
            fi
          done
        fi

        if [ "''${#compose_files[@]}" -eq 0 ]; then
          echo "no .compose-files and no compose file found in $(pwd)" >&2
          exit 1
        fi

        cmd="''${1:-}"
        shift || true

        case "$cmd" in
          up)
            exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" up -d --build --force-recreate "$@"
            ;;
          down)
            exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" down "$@"
            ;;
          *)
            echo "usage: project {up|down}" >&2
            exit 1
            ;;
        esac
      '';
      mkPodmanService = service: {
        "srv-${service}" = {
          Install = {
            WantedBy = [ "default.target" ];
          };
          Unit = {
            Description = "Run compose files for ${service}";
            After = [ "podman.socket" ];
            Wants = [ "podman.socket" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = "%h/src/srv/${service}";
            ExecStart = "${srv}/bin/srv up";
            ExecStop = "${srv}/bin/srv down";
            Environment = [
              "PATH=/home/bloodwolfe/.nix-profile/bin:/run/current-system/sw/bin"
            ];
          };
        };
      };
    in
    lib.mkMerge [
      (mkPodmanService "socket")
      (mkPodmanService "headscale")
      (mkPodmanService "proxy")
      (mkPodmanService "auth")
      (mkPodmanService "site")
      (mkPodmanService "cloud")
      (mkPodmanService "film")
      (mkPodmanService "music")
      (mkPodmanService "library")
      (mkPodmanService "audiobooks")
      (mkPodmanService "gameyfin")
      (mkPodmanService "flame")
      (mkPodmanService "arr")
    ];
}
