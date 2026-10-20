{
  config,
  pkgs,
  inputs,
  ...
}:
let
  subtui = inputs.subtui.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ subtui ];
  sops.secrets."music-tinywolfe-net-username" = { };
  sops.secrets."music-tinywolfe-net-password" = { };

  sops.templates."subtui-credentials" = {
    mode = "0600";
    path = ".config/subtui/credentials.toml";
    content = ''
      [server]
        url = "https://music.tinywolfe.net"
        username = "${config.sops.placeholder."music-tinywolfe-net-username"}"
        password = "${config.sops.placeholder."music-tinywolfe-net-password"}"

      [security]
        redact_credentials_in_logs = true
    '';
  };
}
