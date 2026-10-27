{
  config,
  inputs,
  pkgs,
  ...
}:
let
  piAgents = inputs.agents.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.file.".pi/agent/nix-packages/agents".source =
    config.dotfiles.sourceAt "${config.home.homeDirectory}/src/agents" piAgents;
}
