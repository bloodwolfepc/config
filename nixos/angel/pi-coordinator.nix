# Source-only local candidate. Importing declares options; default enables/installs nothing.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pi-coordinator;
  tools = [
    pkgs.bash
    pkgs.coreutils
    pkgs.python3
  ]
  ++ cfg.workerTools;
  closure = pkgs.closureInfo { rootPaths = tools; };
  worker = pkgs.writeText "pi-tool-worker.py" (builtins.readFile ./pi-tool-helper.py);
  policy = pkgs.runCommand "pi-tool-policy.json" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    export CLOSURE=${closure}/store-paths
    export BASE=${
      pkgs.writeText "pi-tool-policy-base.json" (
        builtins.toJSON {
          workspaces = cfg.workspaces;
          journalRoot = "/var/lib/pi-coordinator/journal";
          boundary = {
            providerCIDRs = cfg.providerCIDRs;
            moduleDigest = builtins.hashString "sha256" (builtins.readFile ./pi-coordinator.nix);
          };
          worker = toString worker;
          python = "${pkgs.python3}/bin/python3";
          bash = "${pkgs.bash}/bin/bash";
          bwrap = "${pkgs.bubblewrap}/bin/bwrap";
          workerPath = lib.makeBinPath tools;
        }
      )
    }
    python3 - <<'PY' > "$out"
    import json, os
    from pathlib import Path
    p = json.loads(Path(os.environ['BASE']).read_text())
    p['runtimePaths'] = Path(os.environ['CLOSURE']).read_text().splitlines()
    print(json.dumps(p))
    PY
  '';
  helper = pkgs.writeShellScriptBin "pi-tool-helper" ''
    exec ${pkgs.python3}/bin/python3 -I ${worker} ${policy}
  '';
  managementSource = pkgs.writeText "pi-batch-management.py" (
    builtins.readFile ./pi-batch-management.py
  );
  management = pkgs.writeShellScriptBin "pi-batch-management" ''
    exec ${pkgs.python3}/bin/python3 -I ${managementSource} ${policy}
  '';
  roots = builtins.attrValues cfg.workspaces;
  skeleton = pkgs.runCommand "pi-coordinator-root" { } ''
    # MountAPIVFS and PrivateTmp need mount targets already present in this immutable root.
    mkdir -p "$out"/{dev,proc,sys,run,tmp,var/tmp,nix/store,etc/ssl/certs,var/lib/pi-coordinator,var/lib/pi-tool-workspaces}
    touch "$out/etc/resolv.conf" "$out/etc/hosts"
    ${lib.concatMapStringsSep "\n" (
      path: ''mkdir -p "$out/var/lib/pi-tool-workspaces/${builtins.baseNameOf path}"''
    ) roots}
  '';
in
{
  options.services.pi-coordinator = {
    enable = lib.mkEnableOption "manual fixed-batch coordinator (separate activation/admission required)";
    entrypoint = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Separately reviewed launcher with qualified minimal credentials/admission; no default live entry.";
    };
    providerCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Explicit reviewed provider AND resolver host CIDRs (/32 or /128); never inherited by tools. No wildcard.";
    };
    workspaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Admitted task IDs to preprovisioned private dedicated ext4 mounts under /var/lib/pi-tool-workspaces. No allocation or formatting.";
    };
    workerTools = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Reviewed pre-realized task toolchain closure; no host store, fetcher or daemon socket.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.entrypoint != null;
        message = "A reviewed launcher/credential/admission binding is required; library source is not activation.";
      }
      {
        assertion =
          cfg.providerCIDRs != [ ]
          && lib.all (cidr: builtins.match "([0-9.]+/32)|([0-9a-fA-F:]+/128)" cidr != null) cfg.providerCIDRs;
        message = "Explicit provider/resolver host CIDRs (/32 or /128) required.";
      }
      {
        assertion =
          roots != [ ]
          && builtins.length roots <= 2
          && builtins.length (lib.unique roots) == builtins.length roots
          && lib.all (p: builtins.match "/var/lib/pi-tool-workspaces/[A-Za-z0-9_-]+" p != null) roots;
        message = "One/two reviewed canonical workspace mount paths required.";
      }
      {
        assertion = lib.all (id: builtins.match "[A-Za-z0-9_-]{8,96}" id != null) (
          builtins.attrNames cfg.workspaces
        );
        message = "Exact admitted task IDs required.";
      }
    ];
    users.groups.pi-coordinator = { };
    users.users.pi-coordinator = {
      isSystemUser = true;
      group = "pi-coordinator";
      home = "/var/lib/pi-coordinator/profile";
    };
    # No WantedBy: even an enabled declaration is not a boot/start permission.
    systemd.services.pi-coordinator = {
      description = "Manually admitted fixed-batch Pi; unqualified local boundary candidate";
      unitConfig.RequiresMountsFor = [ "/var/lib/pi-coordinator" ] ++ roots;
      environment = {
        HOME = "/var/lib/pi-coordinator/profile";
        PI_FIXED_BATCH_HELPER = "${helper}/bin/pi-tool-helper";
        PI_FIXED_BATCH_MANAGER = "${management}/bin/pi-batch-management";
        PI_FIXED_BATCH_JOURNAL = "/var/lib/pi-coordinator/journal";
        PI_FIXED_BATCH_ADMISSION = "/var/lib/pi-coordinator/admission.json";
      };
      serviceConfig = {
        Type = "exec";
        User = "pi-coordinator";
        Group = "pi-coordinator";
        ExecStartPre = "${pkgs.util-linux}/bin/mountpoint -q /var/lib/pi-coordinator";
        ExecStart =
          if cfg.entrypoint == null then "${pkgs.coreutils}/bin/false" else lib.getExe cfg.entrypoint;
        Restart = "no";
        KillMode = "control-group";
        SendSIGKILL = true;
        TimeoutStopSec = 10;
        CPUQuota = "200%";
        MemoryMax = "4G";
        MemorySwapMax = 0;
        TasksMax = 128;
        UMask = "0077";
        RootDirectory = skeleton;
        MountAPIVFS = true;
        BindReadOnlyPaths = [
          "/nix/store"
          "/etc/ssl/certs"
          "/etc/resolv.conf"
          "/etc/hosts"
        ];
        BindPaths = [ "/var/lib/pi-coordinator" ] ++ roots;
        ReadWritePaths = [ "/var/lib/pi-coordinator" ] ++ roots;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectProc = "invisible";
        # Bubblewrap reads kernel proc APIs (overflowuid/overflowgid); pid-only proc hides them.
        ProcSubset = "all";
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
        RestrictNamespaces = [
          "user"
          "mnt"
          "pid"
          "net"
          "ipc"
          "uts"
          "cgroup"
        ];
        IPAddressDeny = "any";
        IPAddressAllow = cfg.providerCIDRs;
        StandardOutput = "null";
        StandardError = "journal";
        LogRateLimitIntervalSec = "1min";
        LogRateLimitBurst = 10;
      };
    };
    system.build.pi-tool-helper = helper;
    system.build.pi-tool-policy = policy;
    system.build.pi-batch-management = management;
  };
}
