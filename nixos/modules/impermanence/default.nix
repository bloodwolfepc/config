{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      # "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/etc/asusd"
      {
        directory = "/var/lib/flatpak";
        user = "root";
        group = "root";
        mode = "0755";
      }
    ];
    files = [
      "/etc/machine-id"
    ];
  };
  boot.initrd =
    let
      wipeScript = (builtins.readFile ./ephemeral-btrfs.sh);
      root = config.fileSystems."/";
      toSystemdDevice =
        device:
        lib.concatStringsSep "-" (
          lib.tail (map (lib.replaceString "-" "\\x2d") (lib.splitString "/" device))
        )
        + ".device";
    in
    {
      supportedFilesystems = [ "btrfs" ];
      systemd.services.restore-root = {
        description = "Rollback btrfs rootfs";
        wantedBy = [ "initrd.target" ];
        requires = [ (toSystemdDevice root.device) ];
        after = [ (toSystemdDevice root.device) ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = wipeScript;
      };
    };
}
