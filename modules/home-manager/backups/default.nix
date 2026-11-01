{ lib, ... }:
let
  singleLine = lib.types.addCheck lib.types.str (
    value: !lib.hasInfix "\n" value && !lib.hasInfix "\r" value
  );
  relativePath = lib.types.addCheck singleLine (
    path:
    path != ""
    && path != "."
    && !lib.hasPrefix "/" path
    && !builtins.elem ".." (lib.splitString "/" path)
  );
in
{
  options.home.backups = lib.mkOption {
    default = { };
    description = ''
      Application-owned backup selections. Paths are relative to the home
      directory; declarations do not enable a backend or imply persistence.
      Multiple modules can contribute paths and exclusions to the same job.
    '';
    apply =
      jobs:
      assert lib.assertMsg
        (lib.all (name: builtins.match "[A-Za-z0-9][A-Za-z0-9_.-]*" name != null) (builtins.attrNames jobs))
        "Backup job names must start with a letter/digit and contain only letters, digits, dots, underscores or hyphens.";
      jobs;
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          paths = lib.mkOption {
            type = lib.types.nonEmptyListOf relativePath;
            description = "Home-relative files, directories or restic wildcard patterns to protect.";
          };
          backupPrepareCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Optional native restic preparation hook. BACKUP_ROOT points to the read-only selection base; write exports under RUNTIME_DIRECTORY.";
          };
          dynamicFilesFrom = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Optional native restic script printing additional prepared export paths.";
          };
          exclude = lib.mkOption {
            type = lib.types.listOf singleLine;
            default = [ ];
            description = "Restic exclusion patterns for this job, not prefixed with the home directory.";
          };
        };
      }
    );
  };
}
