{
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.bitwarden-cli ];

  home.persistence."/persist".directories = [
    {
      directory = ".config/Bitwarden CLI";
      mode = "0700";
    }
    {
      # Preserve the source database until the later password import is verified.
      directory = "Secrets";
      mode = "0700";
    }
  ];

  home.activation.configureBitwardenServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="$HOME/.config/Bitwarden CLI/data.json"
    if [[ ! -e "$config" ]]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$config")"
      $DRY_RUN_CMD ${pkgs.bitwarden-cli}/bin/bw config server https://vault.tinywolfe.net
    fi
  '';
}
