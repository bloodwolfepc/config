{
  config,
  lib,
  pkgs,
  ...
}:
let
  source = config.dotfiles.source;
  agentsProfile = "${config.home.homeDirectory}/.pi/agent/nix-packages/agents/angel";
  pi = "${config.programs.pi-coding-agent.package}/bin/pi";
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
      ".pi/agent/extensions".source = config.lib.file.mkOutOfStoreSymlink "${agentsProfile}/extensions";
      ".pi/agent/skills".source = config.lib.file.mkOutOfStoreSymlink "${agentsProfile}/skills";
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

  systemd.user.services.codex-window-primer = lib.mkIf config.dotfiles.mutable {
    Unit = {
      Description = "Prime the current OpenAI Codex quota window";
      ConditionPathExists = "%h/.pi/agent/auth.json";
    };
    Service = {
      Type = "oneshot";
      UMask = "0077";
      ExecStart = lib.concatStringsSep " " [
        pi
        "--print"
        "--provider openai-codex"
        "--model gpt-5.6-sol"
        "--thinking off"
        "--no-session"
        "--no-tools"
        "--no-extensions"
        "--no-skills"
        "--no-prompt-templates"
        "--no-context-files"
        ''--system-prompt "Reply exactly: OK"''
        ''"Reply exactly: OK"''
      ];
      Environment = [
        "PI_SKIP_VERSION_CHECK=1"
        "PI_TELEMETRY=0"
      ];
    };
  };

  systemd.user.timers.codex-window-primer = lib.mkIf config.dotfiles.mutable {
    Unit.Description = "Prime Codex windows during the working day";
    Timer = {
      OnCalendar = [
        "*-*-* 07:00:00"
        "*-*-* 12:03:00"
        "*-*-* 17:03:00"
      ];
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
