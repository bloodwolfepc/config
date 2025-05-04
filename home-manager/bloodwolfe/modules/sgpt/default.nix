{
  lib,
  config,
  pkgs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "sgpt";
    packages = with pkgs; [
      shell-gpt
      aichat
    ];
    sops.secrets."sgpt-config" = {
      path = "/home/bloodwolfe/.config/shell_gpt/.sgptrc";
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
#type q
#EOF for to string input
#captiol Q for stt

#music contextualization prompt
