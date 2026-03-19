{
  pkgs,
  lib,
  outputs,
  ...
}:
{
  imports = [
    ../modules/account.nix
    ../modules/system
    ../modules/security
    ../modules/applications
    ../modules/terminal
  ];
  home.persistence."/persist".directories = [
    "pictures"
    "videos"
  ];

  home.packages =
    with pkgs;
    [
      internetarchive
      (writeShellScriptBin "bandcamp-dl-for-navi" ''
        ${outputs.customPackages.x86_64-linux.bandcamp-dl}/bin/bandcamp-dl --base-dir /data/music -e -r $1
      '')
    ]
    ++ (with outputs.customPackages.x86_64-linux; [
      bandcamp-dl
    ]);
  systemd.user.services =
    let
      mkPodmanService = service: {
        "composeFiles-${service}" = {
          Install = {
            WantedBy = [ "default.target" ];
          };
          Unit = {
            Description = "Run docker compose files for ${service}";
            After = [ "podman.service" ];
            Wants = [ "podman.service" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = "%h/src/srv/${service}";
            ExecStart = "${pkgs.gnumake}/bin/make start";
            ExecStop = "${pkgs.gnumake}/bin/make stop";
            Environment = [
              "PATH=/home/bloodwolfe/.nix-profile/bin:/run/current-system/sw/bin"
            ];
          };
        };
      };
    in
    lib.mkMerge [
      (mkPodmanService "proxy.waterdreamer.net")
      (mkPodmanService "site.waterdreamer.net")
      (mkPodmanService "library.waterdreamer.net")
      (mkPodmanService "film.waterdreamer.net")
      (mkPodmanService "cloud.waterdreamer.net")
      (mkPodmanService "music.waterdreamer.net")
    ];
}
