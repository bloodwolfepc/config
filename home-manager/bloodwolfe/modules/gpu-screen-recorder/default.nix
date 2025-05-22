{
  lib,
  config,
  pkgs,
  ...
}:
let
  capture = pkgs.writeShellScriptBin "capture" (builtins.readFile ./capture.sh);
  save-clip = pkgs.writeShellScriptBin "save-clip" ''
    killall -SIGUSR1 gpu-screen-recorder
  '';
  attrs = lib.custom.mkHomeApplication {
    name = "gpu-screen-recorder";
    packages = with pkgs; [
      killall
      save-clip
    ];
    systemd.user.services = {
      gpu-screen-recorder = {
        Install = {
          WantedBy = [ "multi-user.taget" ];
        };
        Unit = {
          Description = "Run gpu-screen-recorder as a systemd user service.";
        };
        Service = {
          ExecStart = "${capture}/bin/capture";
          Restart = "always";
          RestartSec = 3;
        };
      };
    };
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
