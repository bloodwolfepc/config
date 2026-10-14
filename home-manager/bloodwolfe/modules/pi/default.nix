{
  config,
  pkgs,
  ...
}:
let
  source = config.dotfiles.source;
in
{
  sops = {
    secrets."kagi-session-token" = { };
  };
  home = {
    packages = with pkgs; [
      # pi-coding-agent
      # jujutsu
      # python3
      # python3Packages.trafilatura

      claude-code
      claude-monitor
      claude-code-router
      claude-agent-acp
    ];
    persistence."/persist".directories = [
      ".pi"
      ".claude"
    ];
    file = {
      ".pi/agent/settings.json".source = source "pi/settings.json" ./settings.json;
      ".pi/agent/keybindings.json".source = source "pi/keybindings.json" ./keybindings.json;
      ".pi/agent/models.json".source = source "pi/models.json" ./models.json;
      ".pi/agent/claude-bridge.json".source = source "pi/claude-bridge.json" ./claude-bridge.json;
      ".pi/agent/extensions".source = source "pi/extensions" ./extensions;
      ".pi/agent/skills".source = source "pi/skills" ./skills;
      ".pi/agent/prompts".source = source "pi/prompts" ./prompts;
    };
  };

  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      pkgs.jujutsu # Used by the jj snapshot extension
      pkgs.python3 # Often used
      pkgs.python3Packages.trafilatura # Used by the web-fetch skill
      pkgs.nodejs
    ];
    context = source "pi/context.md" ./context.md;
  };
  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = true;
    PI_TELEMETRY = false;
  };
}
