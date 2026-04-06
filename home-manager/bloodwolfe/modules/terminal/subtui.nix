# {
#   inputs,
#   pkgs,
#   sops,
#   ...
# }:
# let
#   username = sops.secrets."music-waterdreamer-net-username".plaintext;
#   password = sops.secrets."music-waterdreamer-net-password".plaintext;
#   toTOML = (pkgs.formats.toml { }).generate;
# in
#
# {
#   #sops.secrets."music-waterdreamer-net-password" = { };
#   home.packages = [ (inputs.subtui.packages.${pkgs.stdenv.hostPlatform.system}.default) ];
#   home.file.".config/subtui/credentials.cfg" = {
#     text = ''
#       [server]
#         url = "https://music.waterdreamer.net"
#         username = "${username}"
#         password = "${password}"
#       [security]
#         redact_credentials_in_logs = true
#     '';
#   };
#   #home.file.".config/subtui/credentials.toml".source = toTOML "credentails.toml" {};
# }

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
