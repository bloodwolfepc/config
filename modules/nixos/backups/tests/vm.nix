{ pkgs }:
let
  writer = pkgs.writeText "live-writer.py" ''
    import pathlib, sqlite3, time
    root = pathlib.Path('/persist/users/sample/dataset')
    db = sqlite3.connect(root / 'records.sqlite')
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('CREATE TABLE records (value TEXT)')
    db.execute("INSERT INTO records VALUES ('before')")
    db.commit()
    pathlib.Path('/run/writer-ready').touch()
    while not pathlib.Path('/run/write-after').exists(): time.sleep(0.05)
    db.execute("INSERT INTO records VALUES ('after')")
    db.commit()
    pathlib.Path('/run/after-written').touch()
    while True: time.sleep(1)
  '';
  lockRestic =
    guard:
    import ../locked-restic.nix {
      inherit pkgs guard;
      inherit (pkgs) lib;
      lockFile = "/run/fixture-restic.lock";
    };
  base = {
    package = lockRestic "";
    repository = "/var/lib/test-repo";
    passwordFile = "/etc/test-password";
    paths = [
      "/persist/users/sample/dataset"
      "/persist/users/sample/dataset with spaces"
    ];
    timerConfig = null;
    runCheck = true;
  };
in
pkgs.testers.runNixOSTest {
  name = "snapshot-backup-components";
  nodes.machine = { ... }: {
    imports = [
      (import ../snapshot-restic.nix {
        source = "/persist";
        basePath = "/persist/users/sample";
        snapshotBase = "/persist/.fixture-backup-snapshots";
        jobs = {
          fixture-alpha = base // {
            extraBackupArgs = [
              "--host=fixture"
              "--tag=fixture-alpha"
            ];
            backupPrepareCommand = ''
              test -f "$BACKUP_ROOT/dataset/records.sqlite"
              touch /run/snapshot-ready
              while [[ ! -e /run/test-continue ]]; do sleep 0.1; done
              printf 'prepared export\n' > "$RUNTIME_DIRECTORY/export.txt"
            '';
            dynamicFilesFrom = ''printf '%s\n' "$RUNTIME_DIRECTORY/export.txt"'';
          };
          fixture-ancestor = base // {
            paths = [
              "/persist/users/sample/hidden-parent/dataset"
              "/persist/users/sample/dataset"
            ];
          };
          fixture-pattern = base // {
            paths = [ "/persist/users/sample/dataset/*/payload" ];
          };
          fixture-beta = base // {
            extraBackupArgs = [
              "--host=fixture"
              "--tag=fixture-beta"
            ];
          };
        };
      })
    ];
    services.restic.backups.fixture-maintenance = base // {
      package = lockRestic "test ! -e /run/reject-prune";
      paths = [ ];
      pruneOpts = [
        "--tag fixture-alpha"
        "--group-by host,tags"
        "--keep-last 1"
      ];
    };
    virtualisation.memorySize = 1536;
    virtualisation.diskSize = 4096;
    boot.supportedFilesystems = [ "btrfs" ];
    virtualisation.fileSystems."/persist" = {
      device = "/dev/loop0";
      fsType = "btrfs";
      options = [
        "noauto"
        "subvol=persist"
      ];
    };
    environment.etc.test-password.text = "synthetic-test-password-only";
    environment.systemPackages = [
      pkgs.btrfs-progs
      pkgs.util-linux
      pkgs.python3
      pkgs.sqlite
      pkgs.jq
    ];
    systemd.services.test-writer.serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${writer}";
  };
  testScript = ''
    import json
    machine.start()
    machine.wait_for_unit('multi-user.target')
    machine.succeed('truncate -s 32G /var/lib/btrfs.img; losetup /dev/loop0 /var/lib/btrfs.img; mkfs.btrfs -f /dev/loop0')
    machine.succeed('mkdir -p /mnt/top; mount /dev/loop0 /mnt/top; btrfs subvolume create /mnt/top/persist; umount /mnt/top; systemctl start persist.mount')
    machine.succeed("mkdir -p /persist/users/sample/dataset '/persist/users/sample/dataset with spaces'; echo keep > '/persist/users/sample/dataset with spaces/file'; restic-fixture-alpha init")
    machine.succeed('systemctl start test-writer')
    machine.wait_for_file('/run/writer-ready', timeout=30)
    machine.succeed('systemctl start --no-block restic-backups-fixture-alpha')
    machine.wait_for_file('/run/snapshot-ready', timeout=30)
    machine.succeed('touch /run/write-after')
    machine.wait_for_file('/run/after-written', timeout=30)
    machine.succeed('touch /run/test-continue')
    machine.wait_until_succeeds('test "$(systemctl show -p Result --value restic-backups-fixture-alpha)" = success && test "$(systemctl show -p ActiveState --value restic-backups-fixture-alpha)" = inactive')
    machine.succeed('restic-fixture-alpha restore latest:/run/restic-backups-fixture-alpha/view/users/sample/dataset --target /recovered')
    assert machine.succeed('sqlite3 /recovered/records.sqlite "select group_concat(value) from records"').strip() == 'before'
    assert machine.succeed('sqlite3 /persist/users/sample/dataset/records.sqlite "select group_concat(value) from records"').strip() == 'before,after'
    machine.succeed('restic-fixture-alpha restore latest:/run/restic-backups-fixture-alpha --target /recovered-export')
    assert machine.succeed('head -c 15 /recovered-export/export.txt') == 'prepared export'
    machine.succeed("restic-fixture-alpha restore 'latest:/run/restic-backups-fixture-alpha/view/users/sample/dataset with spaces' --target /recovered-spaces")
    assert machine.succeed('head -c 4 /recovered-spaces/file') == 'keep'
    machine.succeed('systemctl is-active --quiet test-writer')
    machine.succeed('systemctl start restic-backups-fixture-beta; systemctl start restic-backups-fixture-alpha')
    for job in ('alpha', 'beta'):
        assert len(machine.succeed(f'find /persist/.fixture-backup-snapshots/fixture-{job} -mindepth 1 -maxdepth 1 -type d').splitlines()) == 1
    machine.succeed('for d in /persist/.fixture-backup-snapshots/fixture-alpha/*; do test "$(btrfs property get -ts "$d" ro)" = ro=true; done')
    machine.fail('for d in /persist/.fixture-backup-snapshots/fixture-alpha/*; do echo bad > "$d/users/sample/dataset/tamper"; done')
    def snapshots():
        return json.loads(machine.succeed('restic-fixture-alpha snapshots --json'))
    count = len(snapshots())
    def refused(job, reason):
        machine.fail(f'systemctl start restic-backups-fixture-{job}')
        machine.succeed(f'journalctl -u restic-backups-fixture-{job} --no-pager | grep "{reason}"')
        assert len(snapshots()) == count
    machine.succeed('btrfs subvolume create /persist/users/sample/dataset/nested')
    refused('alpha', 'nested subvolume')
    machine.succeed('btrfs subvolume delete /persist/users/sample/dataset/nested')
    machine.succeed('mkdir -p /outside /persist/users/sample/dataset/mounted; mount --bind /outside /persist/users/sample/dataset/mounted')
    refused('alpha', 'crosses a mount')
    machine.succeed('umount /persist/users/sample/dataset/mounted; echo outside > /outside/payload; ln -s /outside /persist/users/sample/dataset/linked')
    refused('pattern', 'symlink outside the snapshot')
    machine.succeed('btrfs subvolume create /persist/users/sample/hidden-parent; mkdir /persist/users/sample/hidden-parent/dataset; echo hidden > /persist/users/sample/hidden-parent/dataset/data')
    refused('ancestor', 'nested subvolume ancestor')
    machine.succeed('restic-fixture-alpha check')
    machine.succeed("systemd-run --unit held-repolock ${pkgs.util-linux}/bin/flock /run/fixture-restic.lock ${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/touch /run/repolock-held; ${pkgs.coreutils}/bin/sleep 60'")
    machine.wait_for_file('/run/repolock-held', timeout=30)
    machine.succeed('systemctl start --no-block restic-backups-fixture-maintenance')
    machine.wait_until_succeeds('pid=$(systemctl show -p MainPID --value restic-backups-fixture-maintenance); grep -q locks_lock_inode_wait /proc/$pid/wchan', timeout=30)
    machine.succeed('touch /run/reject-prune; systemctl stop held-repolock')
    machine.wait_until_succeeds('systemctl is-failed --quiet restic-backups-fixture-maintenance')
    assert len(snapshots()) == count
    machine.succeed('rm /run/reject-prune; systemctl start restic-backups-fixture-maintenance')
    remaining = snapshots()
    assert len(remaining) < count
    assert any('fixture-beta' in snapshot.get('tags', []) for snapshot in remaining)
    machine.succeed('restic-fixture-alpha check')
  '';
}
