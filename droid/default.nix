{ pkgs, ... }:

{
  environment.packages = [ pkgs.vim ];
  system.stateVersion = "24.05";
  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "24.05";
    };
}
