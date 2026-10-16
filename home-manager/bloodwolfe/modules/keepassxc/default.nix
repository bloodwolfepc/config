{ pkgs, ... }:
let
  initArchive = pkgs.writeShellApplication {
    name = "keepassxc-init-archive";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.keepassxc
    ];
    text = ''
      database="$HOME/Secrets/Passwords.kdbx"
      [[ ! -e "$database" ]] || { echo "Database already exists: $database" >&2; exit 1; }
      install -d -m 0700 "$(dirname "$database")"
      keepassxc-cli db-create --set-password "$database"
      keepassxc-cli mkdir "$database" Archive
      chmod 0600 "$database"
      printf 'Created %s with an Archive group.\n' "$database"
    '';
  };
in
{
  home.packages = [
    initArchive
    pkgs.keepassxc
  ];

  home.persistence."/persist".directories = [
    {
      directory = "Secrets";
      mode = "0700";
    }
  ];
}
