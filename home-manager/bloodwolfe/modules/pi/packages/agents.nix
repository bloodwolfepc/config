{ inputs, pkgs, ... }:
let
  piAgents = pkgs.buildPiPackage {
    pname = "pi-agents";
    version = inputs.agents.shortRev or "unstable";
    src = inputs.agents;
    dontNpmInstall = true;
    forceShare = [
      "man"
      "info"
    ];
  };
in
{
  home.file.".pi/agent/nix-packages/agents".source = piAgents;
}
