{ config, lib, inputs, ... }: {
  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "10.10.11.8";
    localAddress = "10.10.10.8";
    forwardPorts = [
      { containerPort = 80; hostPort = 65551; }
      { containerPort = 442; hostPort = 65552; }
    ];
    bindMounts."nextcloud" = {
      hostPath = "/data/srv/nextcould";
      mountPoint = "/var/lib/nextcloud";
      isReadOnly = false;
    };
    config = {
      system.stateVersion = "24.05";
      networking = {
        firewall = {
          allowedTCPports = [ 80 442 ];
        };
        usehostResolvConf = false;
        services.nextcould = {
          enable = true;
          home = "/var/lib/nextcloud";
          https = true;
          hostName = "cloud.waterdreamer.net";
          maxUploadSize = "100G";
          enableImagemagick = true;
          autoUpdateApps.enable = true;
          #config = {
          #  adminuser = "bloodwolfe";
          #};
        };
      };
    };
  };
}
