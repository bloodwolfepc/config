{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "ssh";
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "main" = {
          host = "gitlab.com";
          identitiesOnly = true;
          identityFile = [
            "${config.home.homeDirectory}/.ssh/gitlab_id_ed25519"
          ];
        };
      };
    };
    sops.secrets = {
      "ssh-angel" = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "gitlab_id_ed25519" = {
        path = "${config.home.homeDirectory}/.ssh/gitlab_id_ed25519";
      };
    };
    #on bootstrap eject old key (used to fetch secrets) for sops managed one
    #or use yubikey for initial fetch
    #home.activation.gitlab_id_ed25519 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #  if [ -f "$HOME/.ssh/gitlab_id_25519" && secrets are fetched ]; then
    #    rm "$HOME/.ssh/gitlab_id_25519"
    #  fi
    #'';
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
