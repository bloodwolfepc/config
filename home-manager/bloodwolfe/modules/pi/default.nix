{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  pi = "${config.programs.pi-coding-agent.package}/bin/pi";
in
{
  imports = [ inputs.wolfe-pi.homeManagerModules.default ];

  programs.wolfe-pi = {
    enable = true;
    configPath =
      if config.dotfiles.mutable then
        "${config.home.homeDirectory}/src/wolfe-pi"
      else
        inputs.wolfe-pi.outPath;
    secretFiles.kagiSessionTokenFile = config.sops.secrets."kagi-session-token".path;
  };

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
    package = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
        "--model gpt-6.1-sol"
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
        "*-*-* 17:06:00"
      ];
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
