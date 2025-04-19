{ lib, config, pkgs, ... }: let
  /*
    passOneshots is a file that is sourced by hyperland when mkSubmap is used
    which causes an escape to the escape-to-mode for any key press
  */

  escape-to-mode = "INS";
  mkOneShots = let
    keys = [
      "GRAVE" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "MINUS" "EQUAL"
      "q" "w" "e" "r" "t" "y" "u" "i" "o" "p" "BRACKETLEFT" "BRACKETRIGHT" "BACKSLASH"
      "a" "s" "d" "f" "g" "h" "j" "k" "l" "SEMICOLON" "APOSTROPHE"
      "z" "x" "c" "v" "b" "n" "m" "COMMA" "PERIOD" "SLASH"
    ];
  in
    lib.concatStringsSep "\n" (map 
      (key: "bindi = , ${key}, submap, ${escape-to-mode}") 
      keys
    );
  passOneshots = pkgs.writeText "passOneshots" mkOneShots;

  submaps = [
    "CONFIG" 
    "WS" 
    "DEPLOY" 
    "MIGRATE"
    "REC" 
    "MONITOR" 
    "TOGGLE"
    "UTILITY"
    "COLOR"
    "SCREENSHOT"
    "MENU"
    "DROP"
    "MV->WS"
    "SEND_TO_MONITOR"
  ];
  mkSubmap = submap: ''
    submap = ${submap}
      bindi = , ${config.kb_NML}, submap, NML
      bindi = , Escape, submap, ${escape-to-mode}
      source = ${passOneshots}
    submap = escape
  '';

  submapsNoPassOneshots = [
    "RESIZE" 
    "MOV" 
    "EXEC"
  ];
  mkSubmapNoPassOneshots = submap: ''
    submap = ${submap}
      bindi = , ${config.kb_NML}, submap, NML
      bindi = , Escape, submap, ${escape-to-mode}
    submap = escape
  '';
in {
  attrs = {
    extraConfig = lib.mkAfter ''
      ${lib.concatStringsSep "\n" (map mkSubmap submaps)}
      ${lib.concatStringsSep "\n" (map mkSubmapNoPassOneshots submapsNoPassOneshots)}
      submap = NML
        source = ${config.globals.passOneshots}
      submap = escape
    '';
  };
  options = {
    globals.passOneshots = lib.mkOption {
      type = lib.types.path;
      default = passOneshots;
    };
  };
}
