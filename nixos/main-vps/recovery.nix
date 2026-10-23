{ ... }:
{
  environment.etc = {
    "main-vps/services/auth".source = ./services/auth;
    "main-vps/services/openbao".source = ./services/openbao;
    "main-vps/services/vaultwarden".source = ./services/vaultwarden;
  };

  systemd.tmpfiles.rules = [
    "d /run/main-vps/secrets 0700 root root -"
    "d /srv/dr/auth 0700 root root -"
    "d /srv/dr/auth/data 0700 root root -"
    "d /srv/dr/auth/postgresql 0700 root root -"
    "d /srv/dr/auth/templates 0700 root root -"
    "d /srv/dr/openbao 0700 root root -"
    "d /srv/dr/openbao/data 0700 root root -"
    "d /srv/dr/vaultwarden 0700 root root -"
    "d /srv/dr/vaultwarden/data 0700 root root -"
    "d /srv/dr/vaultwarden/postgresql 0700 root root -"
  ];
}
