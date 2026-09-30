{ config, pkgs, ... }:
let
  vmAddress = "192.168.5.3";
  unseal = pkgs.writeShellScript "srv-openbao-unseal" ''
    set +e
    ${pkgs.openssh}/bin/ssh \
      -F /dev/null \
      -i "$CREDENTIALS_DIRECTORY/ssh-key" \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      -o IdentitiesOnly=yes \
      -o StrictHostKeyChecking=yes \
      -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts \
      root@${vmAddress} < "$CREDENTIALS_DIRECTORY/unseal-key"
    status=$?
    # The VM being offline is expected; the timer retries without leaving a failed unit.
    [[ $status == 255 ]] && exit 0
    exit "$status"
  '';
in
{
  sops.secrets = {
    openbao-unseal-key = {
      mode = "0400";
      restartUnits = [ "srv-openbao-unseal.service" ];
    };
    srv-openbao-unseal-ssh-key = {
      mode = "0400";
      restartUnits = [ "srv-openbao-unseal.service" ];
    };
  };

  programs.ssh.knownHosts.srv-vm = {
    hostNames = [ vmAddress ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACFW/KSvimD8k8SnBJuyCuN8aq6csMUqRrPxfbLRpL2";
  };

  systemd.services.srv-openbao-unseal = {
    description = "Unseal OpenBao in srv-vm";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = [
        "ssh-key:${config.sops.secrets.srv-openbao-unseal-ssh-key.path}"
        "unseal-key:${config.sops.secrets.openbao-unseal-key.path}"
      ];
      ExecStart = unseal;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      UMask = "0077";
    };
  };

  systemd.timers.srv-openbao-unseal = {
    description = "Retry srv-vm OpenBao unseal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "1min";
      Unit = "srv-openbao-unseal.service";
    };
  };
}
