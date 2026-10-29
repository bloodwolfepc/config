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
      required=(
        package.json
        extensions/workflow.ts
        extensions/workflow-policy.ts
        prompts/fast-finish.md
        prompts/incident.md
        prompts/queue-handoff.md
        prompts/secure-promote.md
        prompts/task-plan.md
        prompts/workflow-check.md
        skills/development-workflow/SKILL.md
        skills/intuition-probe/SKILL.md
        skills/intuition-probe/references/blind-prompt.md
        skills/intuition-probe/references/scoring.md
        skills/intuition-probe/scripts/run-blind.sh
        skills/incident-investigation/SKILL.md
        skills/jujutsu/SKILL.md
        skills/nix-shell/SKILL.md
        skills/pi-extension-authoring/SKILL.md
        skills/sub-agents/SKILL.md
        skills/sub-agents/scripts/run.sh
        skills/thinking-scaffold/SKILL.md
        angel/extensions/codex-usage.ts
        angel/extensions/coordinated-work/index.ts
        angel/extensions/handoff.ts
        angel/extensions/coordinated-work/task-coordination.ts
        angel/extensions/jj-snapshot.ts
        angel/extensions/suggest-edit.ts
        angel/extensions/web.ts
        angel/skills/note-refactor/SKILL.md
        angel/skills/note-write/SKILL.md
        angel/skills/personal-tools/SKILL.md
        angel/skills/runelite-query/SKILL.md
        angel/skills/web-fetch/SKILL.md
      )
      missing=
      for relative in "''${required[@]}"; do
        if [[ ! -f "${live}/$relative" ]]; then
          missing=$relative
          break
        fi
      done
      if [[ -z "$missing" ]]; then
        source=${live}
      else
        echo "warning: ${live} is incomplete (missing $missing); using pinned Pi policy" >&2
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
