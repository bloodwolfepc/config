{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Native system backups reuse this existing secret; no re-enrollment/rotation.
  sops.secrets.restic-angel-nextcloud-password = { };
  home.persistence."/persist".directories = [
    "projects/art"
    # Keep legacy state available to older rollback generations.
    {
      directory = ".local/state/angel-state-backup";
      mode = "0700";
    }
  ];
  home.activation.artProjectDirectories = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/gimp"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/krita"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/projects/art/beeref"}
  '';
}
