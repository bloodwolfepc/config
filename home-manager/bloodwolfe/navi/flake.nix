{
  description = "My project dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    { self, nixpkgs }:
    {
      devShells.x86_64-linux.default =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            gnumake
            (writeShellScriptBin "srv-volume-rename" ''
              set -eu

              if [ "$#" -ne 2 ]; then
                echo "usage: srv-rename-volume OLD_VOLUME NEW_VOLUME" >&2
                exit 1
              fi

              old_volume="$1"
              new_volume="$2"

              podman volume create "$new_volume" >/dev/null

              podman run --rm \
                --mount type=volume,src="$old_volume",dst=/from,ro=true \
                --mount type=volume,src="$new_volume",dst=/to \
                docker.io/library/alpine:3.20 \
                sh -euxc 'cd /from && cp -a . /to/'
            '')
            (pkgs.writeShellScriptBin "headscale-nodes-list" ''
              podman exec headscale_headscale_1 headscale nodes list
            '')
            (pkgs.writeShellScriptBin "headscale-node-delete" ''
              if [ $# -ne 1 ]; then
                echo "usage: headscale-node-delete <node-id>" >&2
                exit 1
              fi

              exec podman exec headscale_headscale_1 headscale nodes delete --force -i "$1"
            '')
            (pkgs.writeShellScriptBin "headscale-delete-all-nodes" ''
              set -euo pipefail

              podman exec headscale_headscale_1 headscale nodes list -o json \
                | ${pkgs.jq}/bin/jq -r '.[].id' \
                | while read -r id; do
                    podman exec headscale_headscale_1 headscale nodes delete -i "$id"
                  done
            '')
            (pkgs.writeShellScriptBin "headscale-preauthkeys-list" ''
              exec podman exec headscale_headscale_1 headscale preauthkeys list
            '')
            (pkgs.writeShellScriptBin "headscale-preauthkey-expire" ''
              if [ $# -ne 1 ]; then
                echo "usage: headscale-preauthkey-expire <key-id>" >&2
                exit 1
              fi
              exec podman exec headscale_headscale_1 headscale preauthkeys expire -i "$1"
            '')

            (pkgs.writeShellScriptBin "srv" ''
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
                test)
                  exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" up --build --force-recreate "$@"
                  ;;
                down)
                  exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" down "$@"
                  ;;
                logs)
                  exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" logs -f --tail=100 "$@"
                  ;;
                restart)
                  exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" restart "$@"
                  ;;
                ps)
                  exec ${pkgs.podman}/bin/podman compose "''${compose_files[@]}" ps "$@"
                  ;;
                *)
                  echo "usage: project {up|down|logs|restart|ps}" >&2
                  exit 1
                  ;;
              esac
            '')
          ];
        };
    };
}
