{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "bloodwolfe";
  uid = toString config.users.users.${user}.uid;
  selections = config.home-manager.users.${user}.home.backups;
  secret = name: config.home-manager.users.${user}.sops.secrets.${name}.path;
  auth = "/run/angel-backup-credentials";
  backup = config.services.snapshotBackups;
  names = map (name: "${backup.namespace}-${name}") (builtins.attrNames selections);
  minutes = {
    state = "00";
    legcord = "10";
    terraria = "20";
    anki = "30";
    firefox = "40";
  };
in
{
  imports = [ ../../../modules/nixos/backups ];
  services.snapshotBackups = {
    enable = true;
    source = "/persist";
    basePath = "/persist${config.users.users.${user}.home}";
    notifyUser = user;
    requires = [ "angel-backup-credentials.service" ];
    settings = {
      repository = "rclone:angel:Backups/angel-state";
      passwordFile = "${auth}/password";
      rcloneConfigFile = "${auth}/rclone.conf";
    };
    jobs = lib.mapAttrs (
      name: selection:
      selection
      // {
        timerConfig = {
          OnCalendar = "*-*-* 03:${minutes.${name} or "50"}:00";
          Persistent = true;
          RandomizedDelaySec = "2m";
        };
      }
    ) selections;
  };
  assertions = [
    {
      assertion = config.users.users.${user}.uid != null;
      message = "The backup credential bridge requires an explicitly declared account UID.";
    }
  ];
  # Host-specific credential transport; shared machinery only consumes runtime files.
  systemd.services.angel-backup-credentials = {
    wants = [ "user@${uid}.service" ];
    after = [ "user@${uid}.service" ];
    unitConfig.OnFailure = [ "${backup.namespace}-backup-notify@%n.service" ];
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "angel-backup-credentials";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "yes";
      UMask = "0077";
    };
    postStop = ''
      if [[ "''${SERVICE_RESULT:-failed}" != success ]]; then
        for name in ${lib.escapeShellArgs names}; do touch ${lib.escapeShellArg backup.statusDirectory}/$name.failed; done
      fi
    '';
    script = ''
      set +x
      set -Eeuo pipefail
      ${pkgs.util-linux}/bin/runuser -u ${user} -- ${pkgs.coreutils}/bin/env XDG_RUNTIME_DIR=/run/user/${uid} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus ${pkgs.systemd}/bin/systemctl --user start sops-nix.service
      username=$(<${lib.escapeShellArg (secret "cloud-tinywolfe-net-username")})
      [[ -n "$username" && "$username" != *$'\n'* && "$username" != *$'\r'* ]] || exit 1
      encoded=$(printf '%s' "$username" | ${lib.getExe pkgs.jq} -sRr @uri)
      obscured=$(${lib.getExe pkgs.rclone} obscure - < ${lib.escapeShellArg (secret "cloud-tinywolfe-net-password")})
      printf '[angel]\ntype = webdav\nvendor = nextcloud\nurl = https://cloud.tinywolfe.net/remote.php/dav/files/%s/\nuser = %s\npass = %s\n' "$encoded" "$username" "$obscured" > ${auth}/rclone.conf.new
      ${pkgs.coreutils}/bin/install -m 600 ${lib.escapeShellArg (secret "restic-angel-nextcloud-password")} ${auth}/password.new
      mv ${auth}/rclone.conf.new ${auth}/rclone.conf
      mv ${auth}/password.new ${auth}/password
      unset username encoded obscured
    '';
  };
}
