{ config, lib, inputs, ... }: {
  containers.nixarr = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "10.10.11.5";
    localAddress = "10.10.10.5";
    forwardPorts = [
      { containerPort = 9091; hostPort = 9091; }
      { containerPort = 6767; hostPort = 6767; }
      { containerPort = 8686; hostPort = 8686; }
      { containerPort = 8787; hostPort = 8787; }
      { containerPort = 8989; hostPort = 8989; }
      { containerPort = 7878; hostPort = 7878; }
      { containerPort = 9696; hostPort = 9696; }
      { containerPort = 28960; hostPort = 28960; }
      #{ containerPort = 8080; hostPort = 8080; }
      #{ containerPort = 8083; hostPort = 8083; }
      { containerPort = 8096; hostPort = 8096; }
    ];
    bindMounts."media" = {
      hostPath = "/data/media";
      mountPoint = "/data/media";
      isReadOnly = false;
    };
    extraFlags = [
      "--load-credential=wg-conf:${config.sops.secrets."wg.conf".path}"
    ];
    config = {
      system.stateVersion = "24.05";
      imports = [ inputs.nixarr.nixosModules.default ]; 
      nixpkgs.config.permittedInsecurePackages = [
        "aspnetcore-runtime-6.0.36"
        "aspnetcore-runtime-wrapped-6.0.36"
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-wrapped-6.0.428"
      ];
      networking = {
        firewall = { enable = true; allowedTCPPorts = [
          80 443 8096 9091 6767 8686 8787 8989 7878 9696 8080 8083 28960
        ];};
        useHostResolvConf = lib.mkForce false;
      };
      services.resolved.enable = true;
      networking.nftables.enable = true;
      systemd.services.pass-secrets = {
        enable = true;
        script = ''
          echo $CREDENTIALS_DIRECTORY
          cat $CREDENTIALS_DIRECTORY/wg-conf-propagated
          #will fail no, access
          cat $CREDENTIALS_DIRECTORY/wg-conf
        '';
        serviceConfig = { LoadCredential = "wg-conf-propagated:wg-conf"; };
        wantedBy = [ "multi-user.target" ];
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = "bloodwolfepc@gmail.com";
      };
      services.nginx = {
        enable = true;
        virtualHosts."media.waterdreamer.net" = {
          enableACME = true;
          forceSSL = true;
          locations."/jellyfin" = {
            proxyPass = "https://localhost:8096";
            extraConfig =
              "proxy_ssl_server_name on;" +
              "proxy_pass_header Authorication;"
            ;
          };
        };
        #virtualHosts."read.waterdreamer.net" = {
        #  enableACME = true;
        #  forceSSL = true;
        #  locations."/calibre" = {
        #    proxyPass = "https://localhost:8083";
        #    extraConfig =
        #      "proxy_ssl_server_name on;" +
        #      "proxy_pass_header Authorication;"
        #    ;
        #  };
        #};
      };
      #sops.secrets."wg.conf" = {
      #  format = "binary";
      #  sopsFile = ../../../../../secrets/wg.conf;
      #};
      nixarr = {
        enable = true;
        mediaDir = "/data/media";
        stateDir = "/data/media/.state/nixarr";
        #vpn = {
        #  enable = true;
        #  wgConf = "";
        #};
        jellyfin = { #8096
          enable = true; 
          expose.https = {
            enable = true;
            domainName = "media.waterdreamer.net";
            acmeMail = "bloodwolfepc@gmail.com";
          };
        };
        transmission = { #9091
          enable = true; 
          #vpn.enable = true;
          peerPort = 28960;
        };
        bazarr.enable = true; #6767
        lidarr.enable = true; #8686
        readarr.enable = true; #8787
        sonarr.enable = true; #8989 #sdk
        radarr.enable = true; #7878
        prowlarr.enable = true; #9696
      };
      #services.calibre-server = {
      #  enable = true; #8080
      #  libraries = [ "/data/media/library/books" ];
      #};
      #services.calibre-web = {
      #  enable = true; #8083
      #  #dataDir = "/data/media/.state/calibre-web";
      #  #options = {
      #  #  reverseProxyAuth = {
      #  #    enable = true;
      #  #  };
      #  #};
      #};
    };
  };
}
