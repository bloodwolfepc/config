{ pkgs }:
let
  evaluate =
    settings:
    import (pkgs.path + "/nixos/lib/eval-config.nix") {
      inherit pkgs;
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        ./pi-coordinator.nix
        {
          boot.isContainer = true;
          system.stateVersion = "26.05";
          services.pi-coordinator = settings;
        }
      ];
    };
  disabled = (evaluate { }).config;
  candidate =
    (evaluate {
      enable = true;
      entrypoint = pkgs.hello; # Metadata fixture only; never started.
      providerCIDRs = [ "203.0.113.1/32" ];
      workspaces.offline-task-0001 = "/var/lib/pi-tool-workspaces/offline";
    }).config;
  unit = candidate.systemd.services.pi-coordinator;
  metadata = pkgs.writeText "pi-coordinator-test.json" (
    builtins.toJSON {
      disabledUnit = builtins.hasAttr "pi-coordinator" disabled.systemd.services;
      disabledIdentity = builtins.hasAttr "pi-coordinator" disabled.users.users;
      candidateValid = !libHasFailures candidate;
      wantedBy = unit.wantedBy;
      service = unit.serviceConfig;
      missingBindingRejected = libHasFailures (evaluate { enable = true; }).config;
      broadNetworkRejected =
        builtins.all
          (
            cidr:
            libHasFailures
              (evaluate {
                enable = true;
                entrypoint = pkgs.hello;
                providerCIDRs = [ cidr ];
                workspaces.offline-task-0001 = "/var/lib/pi-tool-workspaces/offline";
              }).config
          )
          [
            "0.0.0.0/0"
            "0.0.0.0/1"
            "203.0.113.0/24"
            "2001:db8::/64"
          ];
    }
  );
  libHasFailures = cfg: builtins.any (a: !a.assertion) cfg.assertions;
in
pkgs.runCommand "pi-coordinator-source-tests"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    PI_UNIT_METADATA = metadata;
    PI_TOOL_POLICY = candidate.system.build.pi-tool-policy;
    PI_BATCH_MANAGEMENT = "${candidate.system.build.pi-batch-management}/bin/pi-batch-management";
    PI_BWRAP = "${pkgs.bubblewrap}/bin/bwrap";
    PI_TEST_BASH = "${pkgs.bash}/bin/bash";
    PI_TEST_BIN_PATH = pkgs.lib.makeBinPath [
      pkgs.bash
      pkgs.coreutils
    ];
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    python3 ${./test-pi-tool-helper.py} ${./pi-tool-helper.py} > "$out" 2>&1
    python3 ${./test-pi-batch-management.py} ${./pi-batch-management.py} >> "$out" 2>&1
  ''
