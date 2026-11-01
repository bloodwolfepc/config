{ pkgs }:
let
  inherit (pkgs) lib;
  declarations =
    (lib.evalModules {
      modules = [
        ../../../home-manager/backups
        { home.backups.alpha.paths = [ "dataset" ]; }
        { home.backups.alpha.paths = [ "folder with spaces" ]; }
        { home.backups.beta.paths = [ "archives/*.txt" ]; }
      ];
    }).config.home.backups;
  eval =
    module:
    (import "${pkgs.path}/nixos/lib/eval-config.nix" {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        ../default.nix
        { system.stateVersion = "26.05"; }
        module
      ];
    }).config;
  fixture = eval {
    networking.hostName = "laptop-one";
    fileSystems."/pool" = {
      device = "/dev/fixture";
      fsType = "btrfs";
    };
    users.users.operator = {
      isNormalUser = true;
      uid = 1101;
    };
    services.snapshotBackups = {
      enable = true;
      namespace = "personal";
      source = "/pool";
      basePath = "/pool/users/operator";
      notifyUser = "operator";
      requires = [ "fixture-credentials.service" ];
      statusDirectory = "/tmp/status;literal";
      settings = {
        repository = "/repository";
        passwordFile = "/run/fixture-password";
        exclude = [ "**/shared-cache" ];
        dynamicFilesFrom = "printf '/prepared-output\\n'";
        backupCleanupCommand = "echo cleanup";
      };
      jobs = declarations;
    };
  };
  other = eval {
    networking.hostName = "other-laptop";
    fileSystems."/storage" = {
      device = "/dev/other";
      fsType = "btrfs";
    };
    services.snapshotBackups = {
      enable = true;
      namespace = "different";
      source = "/storage/";
      settings = {
        repository = "/other-repository";
        passwordFile = "/run/other-password";
      };
      jobs.omega.paths = [ "entirely/different" ];
    };
  };
  disabled = eval { };
  missingUid = eval {
    fileSystems."/pool" = {
      device = "/dev/fixture";
      fsType = "btrfs";
    };
    users.users.operator.isNormalUser = true;
    services.snapshotBackups = {
      enable = true;
      source = "/pool";
      notifyUser = "operator";
      settings = {
        repository = "/repository";
        passwordFile = "/run/password";
      };
      jobs.alpha.paths = [ "data" ];
    };
  };
  differentTransport = eval {
    fileSystems."/pool" = {
      device = "/dev/fixture";
      fsType = "btrfs";
    };
    services.snapshotBackups = {
      enable = true;
      source = "/pool";
      settings = {
        repository = "rclone:fixture:repository";
        passwordFile = "/run/password";
      };
      jobs.alpha = {
        paths = [ "data" ];
        rcloneConfigFile = "/run/different-remote";
      };
    };
  };
  valid =
    name: paths:
    (builtins.tryEval (
      builtins.deepSeq
        (lib.evalModules {
          modules = [
            ../../../home-manager/backups
            { home.backups.${name}.paths = paths; }
          ];
        }).config.home.backups
        true
    )).success;
in
assert
  lib.sort builtins.lessThan fixture.services.restic.backups.personal-alpha.paths == [
    "/run/restic-backups-personal-alpha/view/users/operator/dataset"
    "/run/restic-backups-personal-alpha/view/users/operator/folder with spaces"
  ];
assert
  fixture.services.restic.backups.personal-alpha.extraBackupArgs == [
    "--host=laptop-one"
    "--tag=personal-alpha"
  ];
assert
  fixture.systemd.services.restic-backups-personal-alpha.requires
  == [ "fixture-credentials.service" ];
assert
  fixture.systemd.services.restic-backups-personal-alpha.environment.BACKUP_ROOT
  == "/run/restic-backups-personal-alpha/view/users/operator";
assert
  fixture.systemd.services."personal-backup-notify@".unitConfig.ConditionPathExists
  == "/run/user/1101/bus";
assert
  fixture.systemd.services.personal-backup-stale.environment.DBUS_SESSION_BUS_ADDRESS
  == "unix:path=/run/user/1101/bus";
assert builtins.any (
  check:
  check.message == "Backup notifications require an explicitly declared recipient UID."
  && !check.assertion
) missingUid.assertions;
assert builtins.elem "--tag personal-beta"
  fixture.services.restic.backups.personal-maintenance.pruneOpts;
assert
  other.services.restic.backups.different-omega.paths
  == [ "/run/restic-backups-different-omega/view/entirely/different" ];
assert
  other.systemd.services.restic-backups-different-omega.environment.BACKUP_ROOT
  == "/run/restic-backups-different-omega/view";
assert !(builtins.hasAttr "different-backup-stale" other.systemd.services);
assert disabled.services.restic.backups == { };
assert fixture.services.restic.backups.personal-alpha.exclude == [ "**/shared-cache" ];
assert fixture.services.restic.backups.personal-maintenance.dynamicFilesFrom == null;
assert fixture.services.restic.backups.personal-maintenance.command == [ ];
assert fixture.services.restic.backups.personal-maintenance.backupCleanupCommand == null;
assert builtins.any (
  check:
  check.message == "Snapshot backup jobs must share the configured maintenance repository."
  && !check.assertion
) differentTransport.assertions;
assert valid "sample" [
  "data"
  "archives/*"
  "folder with spaces"
];
assert lib.all (paths: !valid "sample" paths) [
  [ ]
  [ "" ]
  [ "." ]
  [ "/absolute" ]
  [ "../outside" ]
  [ "a\nb" ]
  [ "a\rb" ]
];
assert lib.all (name: !valid name [ "safe" ]) [
  ""
  "../other"
  "two jobs"
  "bad;command"
];
pkgs.runCommand "snapshot-backup-configuration-tests" { } ''
  mkdir -p '/tmp/status;literal'
  ${pkgs.runtimeShell} ${fixture.systemd.services.restic-backups-personal-alpha.serviceConfig.ExecStartPost}
  test -f '/tmp/status;literal/personal-alpha.success'
  test ! -e /tmp/status
  touch "$out"
''
