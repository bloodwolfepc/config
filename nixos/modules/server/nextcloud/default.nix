#WARN: prone to state issues, see:
#https://nixos.org/manual/nixos/stable/index.html#module-services-nextcloud-basic-usage

{ config, pkgs, lib, inputs, ... }: {
  sops.secrets = {
    "bwPass" = { };
  };
  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "10.10.11.8";
    localAddress = "10.10.10.8";
    forwardPorts = [
      { containerPort = 80; hostPort = 25501; }
      { containerPort = 442; hostPort = 25502; }
    ];
    bindMounts."nextcloud" = {
      hostPath = "/data/srv/nextcloud";
      mountPoint = "/var/lib/nextcloud";
      isReadOnly = false;
    };
    extraFlags = [
      "--load-credential=bwPass:${config.sops.secrets."bwPass".path}"
    ];
    config = { pkgs, ... }: {
      system.stateVersion = "24.05";
      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 80 442 ];
        };
        useHostResolvConf = false;
      };
      services.resolved.enable = true;
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud30;
        https = true;
        hostName = "cloud.waterdreamer.net";
        maxUploadSize = "100G";
        enableImagemagick = true;
        autoUpdateApps.enable = true;
        config = {
          adminuser = "bloodwolfe";
          adminpassFile = "$CREDENTIALS_DIRECTORY/adminpass";
        };
      }; 
      systemd.services."nextcloud-setup" = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.LoadCredential = [
          "adminpass:bwPass"
        ];
      };
    };
  };
}
