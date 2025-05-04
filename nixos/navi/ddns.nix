{ config, ... }:
{
  sops.secrets = {
    "ddnssecret" = { };
  };
  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    domains = [ "@" ];
    username = "waterdreamer.net";
    passwordFile = config.sops.secrets."ddnssecret".path;
    use = "web ,web=dynamicdns.park-your-domain.com/getip";
    server = "dynamicdns.park-your-domain.com";
  };
}
