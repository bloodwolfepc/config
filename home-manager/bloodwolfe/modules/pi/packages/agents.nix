{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  piAgents = inputs.agents.packages.${pkgs.stdenv.hostPlatform.system}.default;
  live = "${config.home.homeDirectory}/src/agents";
  target = "${config.home.homeDirectory}/.pi/agent/nix-packages/agents";
in
{
  home.file.".pi/agent/nix-packages/agents" = lib.mkIf (!config.dotfiles.mutable) {
    source = piAgents;
  };

  home.activation.piAgentsSource = lib.mkIf config.dotfiles.mutable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      source=${piAgents}
      if [[ -f "${live}/package.json" && -f "${live}/extensions/workflow.ts" ]]; then
        source=${live}
      else
        echo "warning: ${live} is incomplete; using pinned Pi policy" >&2
      fi

      if [[ -e "${target}" && ! -L "${target}" ]]; then
        echo "error: refusing to replace non-symlink ${target}" >&2
        exit 1
      fi
      run mkdir -p "$(dirname "${target}")"
      run rm -f "${target}.home-manager"
      run ln -sT "$source" "${target}.home-manager"
      run mv -Tf "${target}.home-manager" "${target}"
    ''
  );
}
