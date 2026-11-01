{ pkgs }:
let
  writer = pkgs.writeText "backup-live-writer.py" ''
    import pathlib, sqlite3, time
    root = pathlib.Path('/persist/home/test/profile')
    db = sqlite3.connect(root / 'collection.sqlite')
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('CREATE TABLE notes (value TEXT)')
    db.execute("INSERT INTO notes VALUES ('before')")
    db.commit()
    pathlib.Path('/run/writer-ready').touch()
    while not pathlib.Path('/run/write-after').exists(): time.sleep(0.05)
    db.execute("INSERT INTO notes VALUES ('after')")
    db.commit()
    pathlib.Path('/run/after-written').touch()
    while True: time.sleep(1)
  '';
  lockRestic =
    guard:
    import ./locked-restic.nix {
      inherit pkgs guard;
      inherit (pkgs) lib;
      lockFile = "/run/test-restic.lock";
    };
  base = {
    package = lockRestic "";
    repository = "/var/lib/test-repo";
    passwordFile = "/etc/test-password";
    paths = [
      "/persist/home/test/profile"
      "/persist/home/test/profile with spaces"
    ];
    timerConfig = null;
    runCheck = true;
  };
in
pkgs.testers.runNixOSTest {
  name = "angel-live-snapshot-backups";
  nodes.machine = { lib, ... }: {
    imports = [
      (import ./snapshot-restic.nix {
        source = "/persist";
        jobs = {
          angel-test = base // {
            extraBackupArgs = [
              "--host=angel"
              "--tag=angel-firefox"
            ];
            backupPrepareCommand = ''
              touch /run/snapshot-ready
              while [[ ! -e /run/test-continue ]]; do sleep 0.1; done
            '';
          };
          angel-ancestor = base // {
            paths = [
              "/persist/home/test/hidden-parent/profile"
              "/persist/home/test/profile"
            ];
          };
          angel-pattern = base // {
            paths = [ "/persist/home/test/profile/*/payload" ];
          };
          angel-other = base // {
            extraBackupArgs = [
              "--host=angel"
              "--tag=angel-anki"
            ];
          };
        };
      })
    ];
    services.restic.backups.angel-maintenance = base // {
      package = lockRestic "test ! -e /run/reject-prune";
      paths = [ ];
      pruneOpts = [
        "--tag angel-firefox"
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
    systemd.services.test-writer.serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${writer}";
    };
  };
  testScript = ''
    import json
    machine.start()
    machine.wait_for_unit('multi-user.target')
    machine.succeed('truncate -s 32G /var/lib/btrfs.img; losetup /dev/loop0 /var/lib/btrfs.img; mkfs.btrfs -f /dev/loop0')
    machine.succeed('mkdir -p /mnt/top; mount /dev/loop0 /mnt/top; btrfs subvolume create /mnt/top/persist; umount /mnt/top; systemctl start persist.mount')
    machine.succeed("mkdir -p /persist/home/test/profile '/persist/home/test/profile with spaces'; echo keep > '/persist/home/test/profile with spaces/file'; restic-angel-test init")
    machine.succeed('systemctl start test-writer')
    machine.wait_for_file('/run/writer-ready')
    machine.succeed('systemctl start --no-block restic-backups-angel-test')
    machine.wait_for_file('/run/snapshot-ready')
    machine.succeed('touch /run/write-after')
    machine.wait_for_file('/run/after-written')
    machine.succeed('touch /run/test-continue')
    machine.wait_until_succeeds('systemctl is-active --quiet test-writer && test "$(systemctl show -p Result --value restic-backups-angel-test)" = success && test "$(systemctl show -p ActiveState --value restic-backups-angel-test)" = inactive')
    machine.succeed('restic-angel-test restore latest:/run/restic-backups-angel-test/view/home/test/profile --target /recovered')
    assert machine.succeed('sqlite3 /recovered/collection.sqlite "select group_concat(value) from notes"').strip() == 'before'
    machine.succeed("restic-angel-test restore 'latest:/run/restic-backups-angel-test/view/home/test/profile with spaces' --target /recovered-spaces")
    assert machine.succeed('head -c 4 /recovered-spaces/file').strip() == 'keep'
    assert machine.succeed('sqlite3 /persist/home/test/profile/collection.sqlite "select group_concat(value) from notes"').strip() == 'before,after'
    machine.succeed('systemctl is-active --quiet test-writer')
    machine.succeed('systemctl start restic-backups-angel-other')
    machine.succeed('systemctl start restic-backups-angel-test')
    assert len(machine.succeed('find /persist/.angel-backup-snapshots/angel-test -mindepth 1 -maxdepth 1 -type d').splitlines()) == 1
    assert len(machine.succeed('find /persist/.angel-backup-snapshots/angel-other -mindepth 1 -maxdepth 1 -type d').splitlines()) == 1
    machine.succeed('for d in /persist/.angel-backup-snapshots/angel-test/*; do test "$(btrfs property get -ts "$d" ro)" = ro=true; done')
    machine.fail('for d in /persist/.angel-backup-snapshots/angel-test/*; do echo bad > "$d/home/test/profile/tamper"; done')
    count = len(json.loads(machine.succeed('restic-angel-test snapshots --json')))
    machine.succeed('btrfs subvolume create /persist/home/test/profile/nested')
    machine.fail('systemctl start restic-backups-angel-test')
    assert len(json.loads(machine.succeed('restic-angel-test snapshots --json'))) == count
    machine.succeed('journalctl -u restic-backups-angel-test --no-pager | grep "nested subvolume"')
    machine.succeed('btrfs subvolume delete /persist/home/test/profile/nested')
    machine.succeed('mkdir -p /outside /persist/home/test/profile/mounted; mount --bind /outside /persist/home/test/profile/mounted')
    machine.fail('systemctl start restic-backups-angel-test')
    assert len(json.loads(machine.succeed('restic-angel-test snapshots --json'))) == count
    machine.succeed('journalctl -u restic-backups-angel-test --no-pager | grep "crosses a mount"')
    machine.succeed('umount /persist/home/test/profile/mounted; echo outside > /outside/payload; ln -s /outside /persist/home/test/profile/linked')
    machine.fail('systemctl start restic-backups-angel-pattern')
    machine.succeed('journalctl -u restic-backups-angel-pattern --no-pager | grep "symlink outside the snapshot"')
    assert len(json.loads(machine.succeed('restic-angel-test snapshots --json'))) == count
    machine.succeed('btrfs subvolume create /persist/home/test/hidden-parent; mkdir /persist/home/test/hidden-parent/profile; echo hidden > /persist/home/test/hidden-parent/profile/data')
    machine.fail('systemctl start restic-backups-angel-ancestor')
    machine.succeed('journalctl -u restic-backups-angel-ancestor --no-pager | grep "nested subvolume ancestor"')
    assert len(json.loads(machine.succeed('restic-angel-test snapshots --json'))) == count
    machine.succeed('restic-angel-test check')
    machine.succeed("systemd-run --unit held-repolock ${pkgs.util-linux}/bin/flock /run/test-restic.lock ${pkgs.runtimeShell} -c '${pkgs.coreutils}/bin/touch /run/repolock-held; ${pkgs.coreutils}/bin/sleep 60'")
    machine.wait_for_file('/run/repolock-held', timeout=30)
    machine.succeed('systemctl start --no-block restic-backups-angel-maintenance')
    machine.wait_until_succeeds('pid=$(systemctl show -p MainPID --value restic-backups-angel-maintenance); grep -q locks_lock_inode_wait /proc/$pid/wchan', timeout=30)
    machine.succeed('touch /run/reject-prune; systemctl stop held-repolock')
    machine.wait_until_succeeds('systemctl is-failed --quiet restic-backups-angel-maintenance')
    assert len(json.loads(machine.succeed('restic-angel-test snapshots --json'))) == count
    machine.succeed('rm /run/reject-prune; systemctl start restic-backups-angel-maintenance')
    remaining = json.loads(machine.succeed('restic-angel-test snapshots --json'))
    assert len(remaining) < count
    assert any('angel-anki' in snapshot.get('tags', []) for snapshot in remaining)
    machine.succeed('restic-angel-test check')
  '';
}
