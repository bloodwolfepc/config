{ lib, ... }:
{
  options = {
    kb_RIGHT = lib.mkOption {
      default = "l";
      type = lib.types.str;
    };
    kb_DOWN = lib.mkOption {
      default = "j";
      type = lib.types.str;
    };
    kb_UP = lib.mkOption {
      default = "k";
      type = lib.types.str;
    };
    kb_LEFT = lib.mkOption {
      default = "h";
      type = lib.types.str;
    };
    kb_INS = lib.mkOption {
      default = "i";
      type = lib.types.str;
    };
    kb_NML = lib.mkOption {
      default = "SUPER_L";
      type = lib.types.str;
    };
    kb_EXEC = lib.mkOption {
      default = "e";
      type = lib.types.str;
    };
    kb_WS = lib.mkOption {
      default = "f";
      type = lib.types.str;
    };
    kb_DEPLOY = lib.mkOption {
      default = "d";
      type = lib.types.str;
    };
    kb_TERM = lib.mkOption {
      default = "t";
      type = lib.types.str;
    };
    kb_MIGRATE = lib.mkOption {
      default = "g";
      type = lib.types.str;
    };
    kb_POSITION = lib.mkOption {
      default = "o";
      type = lib.types.str;
    };
    kb_RESIZE = lib.mkOption {
      default = "r";
      type = lib.types.str;
    };
    kb_REC = lib.mkOption {
      default = "c";
      type = lib.types.str;
    };
    kb_MONITOR = lib.mkOption {
      default = "m";
      type = lib.types.str;
    };
  };
}
