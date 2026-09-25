{
  config,
  pkgs,
  ...
}:
let
  configFile = config.dotfiles.source "zellij/config.kdl" ./config.kdl;
  rainbowLayout = config.dotfiles.source "zellij/rainbow_layout.kdl" ./rainbow_layout.kdl;
  dropLayout = config.dotfiles.source "zellij/drop_layout.kdl" ./drop_layout.kdl;
in
{
  home.packages = with pkgs; [
    zellij
    microfetch
    hayabusa
    (pkgs.writeShellScriptBin "src-zellij" ''
      zellij --config ${configFile} "$@"
    '')
    (pkgs.writeShellScriptBin "src-zellij-rainbow" ''
      zellij \
      --config ${configFile} \
      --layout ${rainbowLayout} "$@"
    '')
    (pkgs.writeShellScriptBin "src-zellij-drop" ''
      zellij \
      --config ${configFile} \
      --layout ${dropLayout} "$@"
    '')
    #TODO: How to get new home.SessionVariables after nh os switch if new variables are present?
  ];
  home.file.".config/zellij/config.kdl".source = configFile;
}
