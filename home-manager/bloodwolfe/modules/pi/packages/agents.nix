{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  piAgents = inputs.agents.packages.${pkgs.stdenv.hostPlatform.system}.default;
  piDev = pkgs.writeShellApplication {
    name = "pi-dev";
    runtimeInputs = [
      config.programs.pi-coding-agent.package
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      stable="$HOME/.pi/agent"
      dev="$HOME/.pi/dev-agent"
      live="$HOME/src/agents"

      if [[ ! -f "$live/package.json" ]]; then
        echo "pi-dev: missing agents checkout at $live" >&2
        exit 1
      fi
      install -d -m 0700 "$dev"
      for entry in auth.json models-store.json AGENTS.md claude-bridge.json extensions keybindings.json models.json prompts skills; do
        if [[ -e "$stable/$entry" ]]; then
          ln -sfnT "$stable/$entry" "$dev/$entry"
        fi
      done
      settings_tmp=$(mktemp "$dev/settings.json.XXXXXX")
      jq --arg live "$live" --arg stable "$stable" '
        .packages = [(.packages // [])[] |
          if . == "./nix-packages/agents" then $live
          elif startswith("./") then ($stable + "/" + ltrimstr("./"))
          else . end]
      ' "$stable/settings.json" >"$settings_tmp"
      chmod 0600 "$settings_tmp"
      mv "$settings_tmp" "$dev/settings.json"

      PI_CODING_AGENT_DIR="$dev" exec pi "$@"
    '';
  };
in
{
  home = {
    file.".pi/agent/nix-packages/agents".source = piAgents;
    packages = lib.optionals config.dotfiles.mutable [ piDev ];
  };
}
