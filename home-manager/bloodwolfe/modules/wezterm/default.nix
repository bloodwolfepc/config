{
  config,
  pkgs,
  ...
}:
let
  weztermConfig = config.dotfiles.source "wezterm/wezterm.lua" ./wezterm.lua;
in
{
  home.packages = [ pkgs.wezterm ];
  home.file.".config/wezterm/wezterm.lua".source = weztermConfig;

  xdg.desktopEntries.tinywolfe-terminal = {
    name = "WezTerm";
    exec = "${pkgs.wezterm}/bin/wezterm";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };
  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-terminal-emulator" = [ "tinywolfe-terminal.desktop" ];
      "x-scheme-handler/discord" = [ "legcord.desktop" ];
      "x-scheme-handler/terminal" = [ "tinywolfe-terminal.desktop" ];
    };
    associations.added."x-scheme-handler/discord" = [ "legcord.desktop" ];
  };
}
