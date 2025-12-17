{
  pkgs,
  ...
}:
let
  capture = pkgs.writeShellScriptBin "capture" (builtins.readFile ./capture.sh);
  save-clip = pkgs.writeShellScriptBin "save-clip" ''
    killall -SIGUSR1 gpu-screen-recorder
  '';
in
{
  packages = with pkgs; [
    killall
    save-clip
  ];
  #systemd.user.services = {
  #  gpu-screen-recorder = {
  #    Install = {
  #      WantedBy = [ "default.target" ];
  #    };
  #    Unit = {
  #      Description = "Run gpu-screen-recorder as a systemd user service.";
  #    };
  #    Service = {
  #      ExecStart = "${capture}/bin/capture";
  #      Restart = "always";
  #      RestartSec = 3;
  #    };
  #  };
  #};
}
