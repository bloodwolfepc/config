{
  lib,
  config,
  pkgs,
  ...
}:
let
  source = config.dotfiles.source;
  customExtensions = pkgs.buildPiPackage {
    pname = "extensions";
    version = "unstable";
    src = ./extensions;
    npmDeps = pkgs.importNpmLock { npmRoot = ./extensions; };
    npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  };
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
    settings = {
      compaction = {
        enabled = true;
        keepRecentTokens = 20000;
        reserveTokens = 16384;
      };
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.6-sol";
      enabledModels = [
        "openai-codex/gpt-5.6-sol"
        "openai-codex/gpt-5.6-terra"
        "openai-codex/gpt-5.6-luna"
        # "deepseek/deepseek-v4-flash"
        # "deepseek/deepseek-v4-pro"
        "claude-bridge/claude-opus-5"
        "claude-bridge/claude-sonnet-5"
        "claude-bridge/claude-haiku-4-5"
      ];

      skills = [ (source "pi/skills" ./skills) ];
      prompts = [ (source "pi/prompts" ./prompts) ];
      extensions = [ customExtensions ];
      packages = [
        "git:github.com/DietrichGebert/ponytail"
        # "npm:@caveman-ai/cli"
        # "npm:context-mode"
        # "npm:@juicesharp/rpiv-ask-user-question"
        # "npm:@juicesharp/rpiv-todo"
        # "npm:pi-agent-browser-native"
        # "npm:pi-autoresearch"
        # "npm:pi-background-tasks"
        # # "npm:pi-browser-use"
        # "npm:pi-claude-marketplace"
        # # "npm:pi-hashline-edit-pro" # https://github.com/YuGiMob/pi-hashline-edit-pro
        # # "npm:pi-lens"
        # "npm:pi-mcp-adapter"
        # "npm:pi-powerline-footer"
        # "npm:pi-tool-display" # https://github.com/MasuRii/pi-tool-display
        # "npm:@pi-unipi/notify"
        # "npm:pi-web-access"
        # "npm:@dietrichgebert/ponytail"
        # "npm:@sting8k/pi-vcc"
        # "npm:@tifan/pi-copy-response"
        # "npm:@tifan/pi-handoff"
        # "npm:@tifan/pi-inline-skills"
        # "npm:@tifan/pi-rename"
        # "npm:@tintinweb/pi-subagents"
        # "npm:@vanillagreen/pi-skills-manager"
      ];
      enableInstallTelemetry = false;
      webSearch = {
        kagiSessionTokenFile = config.sops.secrets.kagi-session-token.path or null;
      };
    };
    models.providers.deepseek.modelOverrides = {
      "deepseek-v4-pro".thinkingLevelMap.low = "low";
      "deepseek-v4-flash".thinkingLevelMap.low = "low";
    };
    keybindings = {
      "app.editor.external" = [ "alt+e" ];
    };
  };
  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = true;
    PI_TELEMETRY = false;
  };
}
