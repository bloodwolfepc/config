# Selected only by angel-pi-h1. Declares an inert trial; allocates/starts nothing.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  worker = inputs.pi-fixed-batch-src.packages.${pkgs.stdenv.hostPlatform.system}.pi-fixed-batch;
  taskId = "h1_fixture_20261124";
  workspace = "/var/lib/pi-tool-workspaces/slot-1";
  storeCanary = pkgs.writeText "pi-h1-excluded-store-canary" "synthetic H1 marker, not a credential\n";
  launch = pkgs.writeText "pi-h1-inventory-only.json" (
    builtins.toJSON {
      version = "manual-fixed-launch/v1";
      controller = "${worker}/lib/pi-fixed-batch/scripts/fixed-batch-launch.ts";
      manager = "${config.system.build.pi-batch-management}/bin/pi-batch-management";
      policyDigest = lib.concatStrings (lib.replicate 64 "0");
      initialTrees.${taskId} = lib.concatStrings (lib.replicate 64 "0");
      batch = {
        version = "manual-fixed-batch/v1-no-elapsed";
        approvalId = "h1_fixture_approval_20261124";
        runId = "h1_fixture_run_20261124";
        provider = "openai-codex";
        model = "gpt-6.1-sol";
        accountRef = "h1_synthetic_only";
        helper = "${config.system.build.pi-tool-helper}/bin/pi-tool-helper";
        budget = {
          turns = 1;
          tools = 1;
          inputBytes = 4096;
          capturedBytes = 65536;
        };
        tasks = [
          {
            id = taskId;
            sourceId = "H1-SYNTHETIC-NOT-A-KANEO-TASK";
            base = lib.concatStrings (lib.replicate 40 "0");
            specDigest = builtins.hashString "sha256" "synthetic H1 fixture, no model authority";
            prompt = "Inert H1 fixture. No model run is authorized.";
          }
        ];
      };
    }
  );
  settings = pkgs.writeText "pi-h1-settings.json" (
    builtins.toJSON {
      state = "/var/lib/pi-coordinator";
      inherit
        taskId
        workspace
        storeCanary
        launch
        ;
      helper = "${config.system.build.pi-tool-helper}/bin/pi-tool-helper";
      launcher = "${worker}/bin/pi-fixed-batch";
      workerSource = pkgs.writeText "pi-h1-trusted-workspace-validator.py" (
        builtins.readFile ./pi-tool-helper.py
      );
      python = pkgs.python3.interpreter;
    }
  );
  probe = pkgs.writeShellScriptBin "pi-coordinator-h1" ''
    exec ${pkgs.python3}/bin/python3 -I ${./pi-coordinator-h1.py} ${settings}
  '';
in
{
  services.pi-coordinator = {
    enable = true;
    entrypoint = probe;
    # Deliberately not a provider grant: an inert documentation address only.
    providerCIDRs = [ "203.0.113.1/32" ];
    workspaces.${taskId} = workspace;
  };
  fileSystems = {
    "/var/lib/pi-coordinator" = {
      device = "/persist/pi-coordinator-images/state.ext4";
      fsType = "ext4";
      options = [
        "loop"
        "noauto"
        "nodev"
        "nosuid"
        "noexec"
        "x-systemd.requires-mounts-for=/persist"
      ];
    };
    "${workspace}" = {
      device = "/persist/pi-coordinator-images/slot-1.ext4";
      fsType = "ext4";
      options = [
        "loop"
        "noauto"
        "nodev"
        "nosuid"
        "noexec"
        "x-systemd.requires-mounts-for=/persist"
      ];
    };
  };
  systemd.services.pi-coordinator = {
    startAt = [ ];
    restartIfChanged = false;
    stopIfChanged = false;
  };
  system.build.pi-coordinator-h1 = probe;
  system.build.pi-coordinator-h1-launch = launch;
  system.build.pi-coordinator-h1-settings = settings;
}
