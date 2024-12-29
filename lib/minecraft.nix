{ lib }: 
  with builtins;
  with lib;
rec {

  #TODO mkdirs sudo mkdir -p /data/srv/minecraft/vanilla-mc/{world,world_nether,world_the_end}
  mkMinecraftServer = {
    srvName ? throw "No name given",
    srvMotd ? "",
    srvPackage ? throw "No package given",
    srvDataDir ? "/data/srv/minecraft",

    netHostAddress ? throw "No Host Address Given",
    netLocalAddress ? throw "No Local Adreess Given",
    netPortMinecraft ? 25565,
    netPortRcon ? 35567,

    mcWorlds ? [ "world" "world_nether" "world_the_end" ],

    extraServerConfig ? { },
    config,
    inputs
  }: {
    options = {
      srv.${srvName} = {
        enable = mkEnableOption "enable ${srvName}";
        forward-ports.enable = mkEnableOption "forward ports";
      };
    };
    config = let
      net.ports = {
        minecraft = netPortMinecraft;
        rcon = netPortRcon;
      };
      inherit inputs;
    in {
      containers.${srvName} = mkIf config.srv.${srvName}.enable {
        autoStart = true;
        ephemeral = true;
        privateNetwork = true;
        hostAddress = netHostAddress;
        localAddress = netLocalAddress;
        forwardPorts = #(mkIf config.srv.${srvName}.forward-ports.enable)
          (attrValues (genAttrs (builtins.attrNames net.ports) (portName: {
            containerPort = net.ports.${portName};
            hostPort = net.ports.${portName};
        })));
        bindMounts = let 
          worlds = mcWorlds;
            # chown -R minecraft:minecraft /srv/minecraft/${srvName}
          bindMountAttrs = world: { #TODO chgrp as minecraft
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
              allowedTCPPorts = attrValues net.ports;
#[ 25565 25590 25591 25592 25593 25594 ];
            };
            useHostResolvConf = lib.mkForce false;
          };
          services.resolved.enable = true;
          services.minecraft-servers = {
            enable = true;
            eula = true;
            openFirewall = true;
            servers = {    
              ${srvName} = mkMerge [
                {
                  enable = true;
                  package = srvPackage;
                  serverProperties = { server-port = net.ports.minecraft; };
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
  };
  toJSONFile = expr: builtins.toFile "expr" (builtins.toJSON expr);
  toYAMLFile = expr: pkgs.runCommand "expr.yaml" { } ''
    ${lib.getExe pkgs.remarshal} -i ${toJSONFile expr} -o $out -if json -of yaml
  '';
  toTOMLFile = expr: pkgs.runCommand "expr.toml" { } ''
    ${lib.getExe pkgs.remarshal} -i ${toJSONFile expr} -o $out -if json -of toml
  '';
  toPropsFile = expr: pkgs.writeText "expr.properties" (
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (n: v: "${n}=${if builtins.isBool v then lib.boolToString v else toString v}")
      expr
    )
  );
}
