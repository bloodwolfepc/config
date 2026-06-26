{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    zellij
    microfetch
    hayabusa
    (pkgs.writeShellScriptBin "src-zellij" ''
      zellij --config $FLAKE/hm-modules/zellij/config.kdl "$@"
    '')
    (pkgs.writeShellScriptBin "src-zellij-rainbow" ''
      zellij \
      --config $FLAKE/hm-modules/zellij/config.kdl \
      --layout $FLAKE/hm-modules/zellij/rainbow_layout.kdl "$@"
    '')
    (pkgs.writeShellScriptBin "src-zellij-drop" ''
      zellij \
      --config $FLAKE/hm-modules/zellij/config.kdl \
      --layout $FLAKE/hm-modules/zellij/drop_layout.kdl "$@"
    '')
    #TODO: How to get new home.SessionVariables after nh os switch if new variables are present?
  ];
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
}
