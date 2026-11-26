{ pkgs, workerPackage }:
let
  evaluated = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    inherit pkgs;
    system = pkgs.stdenv.hostPlatform.system;
    specialArgs.inputs.pi-fixed-batch-src.packages.${pkgs.stdenv.hostPlatform.system}.pi-fixed-batch =
      workerPackage;
    modules = [
      ./pi-coordinator.nix
      ./pi-coordinator-install.nix
      {
        boot.isContainer = true;
        system.stateVersion = "26.05";
      }
    ];
  };
  cfg = evaluated.config;
  unit = cfg.systemd.services.pi-coordinator;
  metadata = pkgs.writeText "pi-h1-source-metadata.json" (
    builtins.toJSON {
      valid = builtins.all (a: a.assertion) cfg.assertions;
      wantedBy = unit.wantedBy;
      restartIfChanged = unit.restartIfChanged;
      stopIfChanged = unit.stopIfChanged;
      startAt = unit.startAt;
      service = unit.serviceConfig;
      mounts = builtins.mapAttrs (_: fs: { inherit (fs) device fsType options; }) (
        pkgs.lib.filterAttrs (name: _: pkgs.lib.hasPrefix "/var/lib/pi-" name) cfg.fileSystems
      );
      entrypoint = toString cfg.services.pi-coordinator.entrypoint;
      inherit workerPackage;
    }
  );
in
pkgs.runCommand "pi-coordinator-install-source-tests"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    PI_H1_METADATA = metadata;
    PI_H1_SETTINGS = cfg.system.build.pi-coordinator-h1-settings;
    PI_H1_POLICY = cfg.system.build.pi-tool-policy;
    PI_H1_LAUNCH = cfg.system.build.pi-coordinator-h1-launch;
    PI_FIXED_BATCH = "${workerPackage}/bin/pi-fixed-batch";
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    set -o pipefail
    python3 ${./test-pi-coordinator-h1.py} ${./pi-coordinator-h1.py} 2>&1 | tee "$out"
    python3 ${./test-pi-h1-continuation.py} ${./pi-coordinator-h1.py} ${./test-pi-coordinator-h1.py} 2>&1 | tee -a "$out"
    PI_H1_CONTROLLER_HARNESS=${./pi-coordinator-h1.py} python3 ${./test-pi-h1-continuation-controller.py} ${./pi-h1-continuation-controller.py} 2>&1 | tee -a "$out"
    python3 ${./test-pi-h1-private-failure-inspect.py} ${./pi-h1-private-failure-inspect.py} 2>&1 | tee -a "$out"
    python3 ${./test-pi-h1-private-failure-display.py} ${./pi-h1-private-failure-display.py} 2>&1 | tee -a "$out"
    ${workerPackage}/bin/pi-fixed-batch --help 2>&1 | tee -a "$out"
  ''
