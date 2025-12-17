{ pkgs, config, ... }:
{
  networking.wireguard = {
    enable = true;
  };
  packages = with pkgs; [
    wireguard-tools
  ];
  sops.secrets."wg.conf" = {
    format = "binary";
    sopsFile = ../../../secrets/wg.conf;
  };
  sops.secrets."wg-private-key" = { };
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [
        "10.10.10.6"
        "10.10.11.6"
      ];
      listenPort = 51820;
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      '';
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
      '';
      privateKeyFile = config.sops.secrets."wg-private-key".path;
      peers = [
        {
          allowedIPs = [
            "10.10.10.7"
            "10.10.11.7"
          ];
          publicKey = "IPOyaLNFFM1aDyiPUtHe48QFF01a+/JXIp11V/bHRQU=";
        }
      ];
    };
  };
}
