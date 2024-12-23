
  #TODO create a function for bindings from normal mode #${lib.concatStringsSep "\n" (map mkNormalMapings submaps )}
  #mkNormalMapings = kbKey: map: ''
  #  submap = ${config.kb_NML}
  #    bindi = ${kbKey}, submap, ${map}
  #  submap = escape
  #'';

{ lib, config, pkgs, ... }: let
  mkOneShots = let
    escape-to-mode = "INS";
    keys = [
      "GRAVE" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "MINUS" "EQUAL"
      "q" "w" "e" "r" "t" "y" "u" "i" "o" "p" "BRACKETLEFT" "BRACKETRIGHT" "BACKSLASH"
      "a" "s" "d" "f" "g" "h" "j" "k" "l" "SEMICOLON" "APOSTROPHE"
      "z" "x" "c" "v" "b" "n" "m" "COMMA" "PERIOD" "SLASH"
    ];
  in
    lib.concatStringsSep "\n" (map (key: "bindi = , ${key}, submap, ${escape-to-mode}") keys);
  passOneshots = pkgs.writeText "passOneshots" mkOneShots;
  submaps = [
    "CONFIG" "WS" "DEPLOY" "MIGRATE"
    "POSITION" "REC" "MONITOR" "TMUX" "TOGGLE"
  ];
  submapsNoPassOneshots = [
    "RESIZE" "EXEC"
  ];
  mkSubmap = map: ''
    submap = ${map}
      bindi = ,${config.kb_INS}, submap, INS
      bindi = ,${config.kb_NML}, submap, NML
      source = ${passOneshots}
    submap = escape
  '';
  mkSubmapNoPassOneshots = map: ''
    submap = ${map}
      bindi = ,${config.kb_INS}, submap, INS
      bindi = ,${config.kb_NML}, submap, NML
    submap = escape
  '';
in {
  attrs.extraConfig = ''
    ${lib.concatStringsSep "\n" (map mkSubmap submaps)}
    ${lib.concatStringsSep "\n" (map mkSubmapNoPassOneshots submapsNoPassOneshots)}
    submap = NML
      source = ${config.globals.passOneshots}
    submap = escape
  '';
  options = let
    mkKb = default: lib.mkOption {
      inherit default;
      type = lib.types.str;
    };
  in {
    globals.passOneshots = lib.mkOption {
      type = lib.types.path;
      default = passOneshots;
    };
    kb_RIGHT = mkKb "l";
    kb_DOWN = mkKb "j";
    kb_UP = mkKb "k";
    kb_LEFT = mkKb "h";
    kb_INS = mkKb "i";
    kb_NML = mkKb "SUPER_L";
    kb_EXEC = mkKb "e";
    kb_WS = mkKb "f";
    kb_DEPLOY = mkKb "d";
      #kb_TERM = mkKb "t";
    kb_MIGRATE = mkKb "g";
    kb_POSITION = mkKb "o";
    kb_RESIZE = mkKb "r";
    kb_REC = mkKb "c";
    kb_MONITOR = mkKb "m";
    kb_CONFIG = mkKb "s";
    kb_TOGGLE = mkKb "t";
    kb_TMUX = mkKb "SPACE";
  };
}
