{
  config,
  lib,
  pkgs,
  ...
}:
let
  daemon = pkgs.nextcloud-sync-daemon;
  syncRoot = "${config.xdg.dataHome}/nextcloud-sync";
  fontDirectory = "${syncRoot}/fonts";

  # shortcut: exports are additive, add a manifest if retired fonts need automatic cleanup.
  fontFiles = {
    "unscii-16-full.otf" = "${pkgs.unscii}/share/fonts/opentype/unscii-16-full.otf";
  };

  exportFonts = pkgs.writeShellApplication {
    name = "nextcloud-export-fonts";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      install -d -m 0755 ${lib.escapeShellArg fontDirectory}
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: source:
          "install -C -m 0644 ${lib.escapeShellArg source} ${lib.escapeShellArg "${fontDirectory}/${name}"}"
        ) fontFiles
      )}
    '';
  };

  syncDirectories = {
    fonts = {
      localDirectory = fontDirectory;
      remotePath = "/fonts";
      prepare = lib.getExe exportFonts;
    };
    notebook = {
      localDirectory = "${config.home.homeDirectory}/notebook";
      remotePath = "/notebook";
    };
  };

  mkRunner =
    name: sync:
    pkgs.writeShellApplication {
      name = "nextcloud-sync-${name}";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.jq
      ];
      text = ''
              username="$(<${config.sops.secrets.cloud-tinywolfe-net-username.path})"
              [[ "$username" =~ ^[[:alnum:]_.@+-]+$ ]] || {
                echo "invalid Nextcloud username" >&2
                exit 1
              }

              install -d -m 0755 ${lib.escapeShellArg sync.localDirectory}
              runtime_directory="''${XDG_RUNTIME_DIR:?}/nextcloud-sync-daemon"
              install -d -m 0700 "$runtime_directory"
              export TMPDIR="$runtime_directory/${name}"
              install -d -m 0700 "$TMPDIR"
              config_file="$runtime_directory/${name}.yaml"
              umask 077

              password="$(<${config.sops.secrets.cloud-tinywolfe-net-password.path})"
              remote_url="https://cloud.tinywolfe.net/remote.php/dav/files/$username"
              remote_path=${lib.escapeShellArg sync.remotePath}
              IFS=/ read -ra remote_parts <<<"''${remote_path#/}"
              for part in "''${remote_parts[@]}"; do
                remote_url="$remote_url/$part"
                status="$(${lib.getExe pkgs.jq} -nr --arg credentials "$username:$password" \
                  '"user = " + ($credentials | @json)' | \
                  ${lib.getExe pkgs.curl} --config - --silent --show-error \
                    --output /dev/null --write-out '%{http_code}' --request MKCOL "$remote_url")"
                [[ "$status" == 201 || "$status" == 405 ]] || {
                  echo "could not create remote directory $remote_url (HTTP $status)" >&2
                  exit 1
                }
              done
              unset password

              cat >"$config_file" <<EOF
        server:
          url: https://cloud.tinywolfe.net
          username: "$username"
          password_file: ${config.sops.secrets.cloud-tinywolfe-net-password.path}
        sync:
          local_dir: ${sync.localDirectory}
          remote_path: ${sync.remotePath}
          nextcloudcmd: ${lib.getExe' pkgs.nextcloud-client "nextcloudcmd"}
          timeout: 5m
        watch:
          enabled: true
          debounce: 2s
          cooldown: 30s
          exclude:
            - '\.sync_.*\.db'
        notify_push:
          enabled: true
        poll:
          enabled: true
          interval: 10m
        EOF
              ${lib.getExe daemon} --once --config "$config_file"
              exec ${lib.getExe daemon} --config "$config_file"
      '';
    };
in
{
  sops.secrets."cloud-tinywolfe-net-username" = { };
  sops.secrets."cloud-tinywolfe-net-password" = { };

  home.packages = [
    daemon
    exportFonts
  ];

  systemd.user = {
    services = lib.mapAttrs' (
      name: sync:
      lib.nameValuePair "nextcloud-sync-${name}" {
        Unit = {
          Description = "Sync ${name} with Nextcloud";
          After = [
            "network-online.target"
            "sops-nix.service"
          ];
          Wants = [ "network-online.target" ];
          ConditionPathExists = [
            config.sops.secrets.cloud-tinywolfe-net-username.path
            config.sops.secrets.cloud-tinywolfe-net-password.path
          ];
        };
        Service = {
          ExecStart = lib.getExe (mkRunner name sync);
          Restart = "on-failure";
          RestartSec = "30s";
        }
        // lib.optionalAttrs (sync ? prepare) {
          ExecStartPre = sync.prepare;
        };
        Install.WantedBy = [ "default.target" ];
      }
    ) syncDirectories;
    startServices = true;
  };

  home.persistence."/persist".directories = [
    "cloud"
    "notebook"
    ".local/share/nextcloud-sync"
  ];
}
