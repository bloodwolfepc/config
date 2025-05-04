{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.mc = mkOption {
    type = types.listOf (
      types.submodule {
        options = {
          motd = mkOption {
            type = types.str;
            example = "DP-1";
            default = "never knows best.";
          };
          mc-port-default = mkOption {
            type = types.int;
            example = "25565";
          };
          rcon-port-default = mkOption {
            type = types.int;
            example = "25567";
          };
        };
      }
    );
    default = [ ];
  };
}
