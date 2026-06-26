{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.packages = [ (inputs.subtui.packages.${pkgs.stdenv.hostPlatform.system}.default) ];
  sops.secrets."music-waterdreamer-net-username" = { };
  sops.secrets."music-waterdreamer-net-password" = { };

  sops.templates."subtui-credentials" = {
    mode = "0600";
    path = ".config/subtui/credentials.toml";
    content = ''
      [server]
        url = "https://music.waterdreamer.net"
        username = "${config.sops.placeholder."music-waterdreamer-net-username"}"
        password = "${config.sops.placeholder."music-waterdreamer-net-password"}"

      [security]
        redact_credentials_in_logs = true
    '';
  };
}
