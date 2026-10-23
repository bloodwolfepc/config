{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  root = config.fileSystems."/";
  rootDeviceUnit =
    lib.concatStringsSep "-" (
      lib.tail (map (lib.replaceString "-" "\\x2d") (lib.splitString "/" root.device))
    )
    + ".device";
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/lib/acme"
      "/var/lib/caddy"
      "/var/lib/containers"
      "/var/lib/nixos"
      "/var/lib/postfix"
      "/var/lib/redis-rspamd"
      "/var/lib/rspamd"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };

  boot.initrd = {
    supportedFilesystems = [ "btrfs" ];
    systemd = {
      enable = true;
      services.restore-root = {
        description = "Replace the ephemeral Btrfs root subvolume";
        wantedBy = [ "initrd.target" ];
        requires = [ rootDeviceUnit ];
        after = [ rootDeviceUnit ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir /btrfs
          mount -t btrfs -o subvolid=5 ${lib.escapeShellArg root.device} /btrfs
          mkdir -p /btrfs/old_roots
          if test -e /btrfs/root; then
            timestamp="$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%SZ)"
            mv /btrfs/root "/btrfs/old_roots/$timestamp"
          fi
          ${pkgs.findutils}/bin/find /btrfs/old_roots -mindepth 1 -maxdepth 1 -mtime +7 \
            -exec ${pkgs.btrfs-progs}/bin/btrfs subvolume delete {} \;
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create /btrfs/root
          umount /btrfs
        '';
      };
    };
  };
}
