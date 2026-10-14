{ pkgs, ... }: {
  home = {
    file.".pi/agent/nix-packages/agent-browser".source = pkgs.agent-browser;
    packages = [ pkgs.agent-browser ];
  };
}
