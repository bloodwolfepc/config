{ lib }: 
  with builtins;
  with lib;
rec {

  mkMinecraftServer = {
    srvName ? throw "No name given",
    srvMotd ? "",
    srvPackage ? throw "No package given",
    srvDataDir ? "/data/srv/minecraft",

    netHostAddress ? throw "No Host Address Given",
    netLocalAddress ? throw "No Local Adreess Given",
    netPortMinecraft ? "25565",
    netPortRcon ? "35567",

    mcWorlds ? [ "world" "world_nether" "world_the_end" ],

    extraSeverConfig ? { },
    config
  }: 
  {
    config = {
      srv.${srvName} = {
        autoStart = true;
        ephemeral = true;
        privateNetwork = true;
        ports = attrValues netPorts;
        hostAddress = netHostAddress;
        localAddress = netLocalAddress;
        forwardPorts = let
          net.ports = {
            minecraft = "${netPortMinecraft}";
            rcon = "${netPortRcon}";
          };
        in
          attrValues (genAttrs (builtins.attrNames net.ports) (portName: {
          containerPort = net.ports.${portName};
          hostPort = net.ports.${portName};
          }));
        };
        bindmounts = let 
          worlds = mcWorlds;
          bindMountAttrs = world: {
            hostPath = "${srvDataDir}/${srvName}/${world}";
            mountPoint = "/srv/minecraft/${srvName}/${world}";
            isReadOnly = false;
          };
        in genAttrs worlds bindMountAttrs;
        config = { pkgs, ... }: {
          imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
          nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
          system.stateVersion = "24.05";
          networking = {
            firewall = { 
              enable = true;
              allowedTCPPorts = attrValues netPorts;
            };
            useHostResolvConf = lib.mkForce false;
          };
          services.resolved.enable = true;
          services.minecraft-server = {
            enable = true;
            eula = true;
            openFirewall = true;
            servers = {    
              ${srvName} = mkMerge [
                {
                  enable = true;
                  package = srvPackage;
                  serverProperties = { server-port = netPortsMinecraft; };
                  symlinks = {
                    "forwarding.secret" = pkgs.writeTextFile {
                      name = "forwarding.secret";
                      text = "ExampleForwardingSecret";
                    };
                  };
                }
                extraServerConfig
              ];
            };
          };
        };
      };
    };
    options = {
      srv.${srvName} = {
        enable = mkEnableOption "enable ${srvName}";
      };
    };
  }
