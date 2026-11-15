{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "srv-backup-shared-lock";
  nodes.machine = { config, lib, ... }: {
    imports = [ ./backups.nix ];
    # Only the unused secret path option is needed; no secret or Borg archive is read.
    options.sops.secrets = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.submodule {
        options.path = lib.mkOption { type = lib.types.str; default = "/unused-fixture-secret"; };
      });
    };
    config = {
      virtualisation.memorySize = 768;
      systemd.tmpfiles.rules = [
        "d /root/.config/borg 0700 root root -"
        "d /root/.cache/borg 0700 root root -"
        "d /backup/srv 0700 root root -"
      ];
      systemd.timers = lib.genAttrs
        [ "borgbackup-job-srv-vm" "borgbackup-job-sync-bu" "borgbackup-job-persist-bu" ]
        (_: { wantedBy = lib.mkForce [ ]; });
      systemd.services = {
        borgbackup-job-srv-vm.serviceConfig = {
          TimeoutStartSec = 30;
          ExecStart = lib.mkForce (pkgs.writeShellScript "borg-lock-probe" ''
            set -euo pipefail
            ${config.services.borgbackup.jobs.srv-vm.preHook}
            ${pkgs.coreutils}/bin/stat -c '%d:%i' /run/lock/srv-backup.lock > /backup/srv/lock-inode
            if ${pkgs.coreutils}/bin/touch /run/lock/unrelated; then
              echo 'Sandbox unexpectedly permits unrelated lock writes' >&2
              exit 1
            fi
            ${pkgs.coreutils}/bin/touch /backup/srv/borg-entered
            until [[ -e /backup/srv/release ]]; do ${pkgs.coreutils}/bin/sleep 0.1; done
          '');
        };
        # Same effective Borg sandbox, but with the old missing writable exception.
        broken-borg-lock.serviceConfig = config.systemd.services.borgbackup-job-srv-vm.serviceConfig // {
          ReadWritePaths = builtins.filter (path: path != "/run/lock/srv-backup.lock")
            config.systemd.services.borgbackup-job-srv-vm.serviceConfig.ReadWritePaths;
        };
      };
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("test -f /run/lock/srv-backup.lock")
    assert machine.succeed("stat -c '%a %U' /run/lock/srv-backup.lock").strip() == "600 root"
    inode = machine.succeed("stat -c '%d:%i' /run/lock/srv-backup.lock")
    machine.succeed("touch /backup/srv-staging/.complete /backup/srv-staging/old-snapshot")

    with subtest("old sandbox reproduces the lock-path failure"):
        machine.succeed("systemctl start --no-block broken-borg-lock.service")
        machine.wait_until_succeeds("test $(systemctl show broken-borg-lock.service -p ActiveState --value) = failed")
        output = machine.succeed("journalctl -u broken-borg-lock.service --no-pager -o cat")
        assert "/run/lock/srv-backup.lock: Read-only file system" in output, output
        machine.succeed("test ! -e /backup/srv/borg-entered")

    with subtest("exact-file exception preserves shared locking and sandbox"):
        machine.succeed("systemctl start --no-block borgbackup-job-srv-vm.service")
        machine.wait_until_succeeds("test -f /backup/srv/borg-entered")
        assert inode == machine.succeed("cat /backup/srv/lock-inode")
        machine.fail("${pkgs.util-linux}/bin/flock -n /run/lock/srv-backup.lock -c true")
        # Tmpfiles must not replace an inode that a backup is currently locking.
        machine.succeed("systemd-tmpfiles --create --prefix=/run/lock/srv-backup.lock")
        assert inode == machine.succeed("stat -c '%d:%i' /run/lock/srv-backup.lock")
        machine.fail("${pkgs.util-linux}/bin/flock -n /run/lock/srv-backup.lock -c true")
        machine.succeed("test ! -e /run/lock/unrelated")
        assert machine.succeed("systemctl show borgbackup-job-srv-vm.service -p ProtectSystem --value").strip() == "strict"

        # Use the real promotion script on fictional directories in this VM only.
        machine.succeed("touch /backup/srv-incoming/.complete /backup/srv-incoming/new-snapshot")
        machine.succeed("systemctl start --no-block srv-backup-promote.service")
        machine.wait_until_succeeds("test $(systemctl show srv-backup-promote.service -p MainPID --value) -gt 0")
        machine.succeed("test -f /backup/srv-staging/old-snapshot && test -f /backup/srv-incoming/new-snapshot")
        machine.succeed("touch /backup/srv/release")
        machine.wait_until_succeeds("test $(systemctl show srv-backup-promote.service -p ActiveState --value) = inactive")
        assert machine.succeed("systemctl show srv-backup-promote.service -p Result --value").strip() == "success"
        machine.wait_until_succeeds("test $(systemctl show borgbackup-job-srv-vm.service -p ActiveState --value) = inactive")
        assert machine.succeed("systemctl show borgbackup-job-srv-vm.service -p Result --value").strip() == "success"
        machine.succeed("test -f /backup/srv-staging/new-snapshot && test ! -e /backup/srv-staging/old-snapshot")
        machine.succeed("test -d /backup/srv-incoming && test ! -e /backup/srv-incoming/.complete")
        assert inode == machine.succeed("stat -c '%d:%i' /run/lock/srv-backup.lock")
        machine.succeed("${pkgs.util-linux}/bin/flock -n /run/lock/srv-backup.lock -c true")
  '';
}
