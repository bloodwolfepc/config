{ lib, config, pkgs, ... }: let 
  attrs = lib.custom.mkHomeApplication {
    name = "taskwarrior";
    packages = with pkgs; [
      taskwarrior-tui
    ]; 
    syncDirs = [
      ".config/task" #TODO should only worry about taskrc
    ];
    programs.taskwarrior = { 
      enable = true; 
      package = pkgs.taskwarrior3;
    };
    inherit config;
  };
in {
  inherit (attrs) options config;
}
