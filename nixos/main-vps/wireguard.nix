{
  lib,
  pkgs,
  ...
}:
let
  homePublicKey = "EXw5GNhM+m+L8rM3Ip35dtLJDDMfegmMcPONI+H93EY=";
in
{
  networking = {
    firewall.allowedUDPPorts = [ 51820 ];
    wireguard.interfaces.wg-home = {
      ips = [ "10.77.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/persist/system/etc/wireguard/wg-home.key";
      peers = lib.optionals (homePublicKey != null) [
        {
          publicKey = homePublicKey;
          allowedIPs = [ "10.77.0.2/32" ];
        }
      ];
    };
  };

  # networkd cannot use networking.wireguard's built-in key generator, so create
  # the persistent key before networkd loads the WireGuard netdev.
  systemd.services.wireguard-wg-home-key = {
    description = "Generate the persistent VPS WireGuard key";
    requiredBy = [ "systemd-networkd.service" ];
    before = [ "systemd-networkd.service" ];
    unitConfig.RequiresMountsFor = "/persist";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -d -o root -g root -m 0700 /persist/system/etc/wireguard
      if [[ ! -s /persist/system/etc/wireguard/wg-home.key ]]; then
        umask 077
        ${pkgs.wireguard-tools}/bin/wg genkey > /persist/system/etc/wireguard/wg-home.key
      fi
    '';
  };
}
