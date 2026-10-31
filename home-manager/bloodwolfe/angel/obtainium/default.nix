{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "droid-obtainium-list";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        export DROID_OBTAINIUM_USERNAME_FILE=${config.sops.secrets.cloud-tinywolfe-net-username.path}
        export DROID_OBTAINIUM_PASSWORD_FILE=${config.sops.secrets.cloud-tinywolfe-net-password.path}
        exec python3 ${./obtainium_list.py} "$@"
      '';
    })
  ];
}
