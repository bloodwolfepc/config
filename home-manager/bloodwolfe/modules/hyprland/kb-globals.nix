{ lib, ... }:
{
  options =
    let
      mkKb =
        default:
        lib.mkOption {
          inherit default;
          type = lib.types.str;
        };
    in
    {
      kb_RIGHT = mkKb "l";
      kb_DOWN = mkKb "j";
      kb_UP = mkKb "k";
      kb_LEFT = mkKb "h";

      kb_INS = mkKb "i";
      kb_NML = mkKb "SUPER_L";
      kb_EXEC = mkKb "e";
      kb_WS = mkKb "f";
      kb_DEPLOY = mkKb "d";
      kb_MIGRATE = mkKb "g";
      kb_POSITION = mkKb "o";
      kb_RESIZE = mkKb "r";
      kb_REC = mkKb "c";
      kb_MONITOR = mkKb "m";
      kb_CONFIG = mkKb "s";
      kb_TOGGLE = mkKb "t";
    };
}
