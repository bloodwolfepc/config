{
  pkgs,
  ...
}:
let
  gpusr-capture = pkgs.writeShellScriptBin "gpursr-capture" ''
    gpu-screen-recorder \
    -w "focused" \
    -f 60 \
    -r 360 \
    -s 2560x1440 \
    -q medium \
    -a "default_output|default_input" \
    -c mp4 \
    -df yes \
    -o "videos/gpu-screen-recorder"
  '';
  gpusr-save = pkgs.writeShellScriptBin "gpusr-save" ''
    killall -SIGUSR1 gpu-screen-recorder
  '';
in
{
  home.packages = [
    gpusr-capture
    gpusr-save
    pkgs.killall
  ];

  systemd.user.services = {
    gpu-screen-recorder = {
      Install = {
        WantedBy = [ "default.target" ];
      };
      Unit = {
        Description = "gpu-screen-recorder service.";
      };
      Service = {
        ExecStart = "${gpusr-capture}/bin/capture";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
