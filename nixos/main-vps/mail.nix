{ config, pkgs, ... }:
let
  domain = "tinywolfe.net";
  hostname = "mx.${domain}";
  relayRecipients = pkgs.writeText "postfix-relay-recipients" ''
    abuse@${domain} OK
    authentik@${domain} OK
    betawolfe1@${domain} OK
    betawolfe2@${domain} OK
    betawolfe3@${domain} OK
    bloodwolfe@${domain} OK
    january@${domain} OK
    janvv@${domain} OK
    postmaster@${domain} OK
    tinywolfe@${domain} OK
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    25
    80
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "postmaster@${domain}";
    certs.${hostname} = {
      group = config.services.postfix.group;
      listenHTTP = ":80";
      reloadServices = [ "postfix.service" ];
    };
  };

  services.postfix = {
    enable = true;
    enableSubmission = false;
    enableSubmissions = false;
    mapFiles.relay_recipients = relayRecipients;
    transport = ''
      ${domain} smtp:[10.77.0.2]:2525
    '';
    settings.main = {
      myhostname = hostname;
      mydomain = domain;
      myorigin = "$myhostname";
      mydestination = [
        "$myhostname"
        "localhost"
      ];
      inet_interfaces = "all";
      inet_protocols = "ipv4";
      relay_domains = [ domain ];
      relay_recipient_maps = [ "hash:/etc/postfix/relay_recipients" ];
      smtpd_relay_restrictions = [
        "permit_mynetworks"
        "reject_unauth_destination"
      ];
      smtpd_recipient_restrictions = [
        "reject_non_fqdn_recipient"
        "reject_unknown_recipient_domain"
        "reject_unauth_destination"
      ];
      disable_vrfy_command = true;
      smtpd_helo_required = true;
      strict_rfc821_envelopes = true;
      recipient_delimiter = "+";
      message_size_limit = 52428800;
      maximal_queue_lifetime = "5d";
      bounce_queue_lifetime = "5d";
      delay_warning_time = "4h";
      smtp_tls_security_level = "may";
      smtpd_tls_security_level = "may";
      smtpd_tls_chain_files = [
        "/var/lib/acme/${hostname}/key.pem"
        "/var/lib/acme/${hostname}/fullchain.pem"
      ];
      milter_default_action = "tempfail";
      milter_protocol = 6;
    };
  };

  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings.server.interface = [ "127.0.0.1" ];
  };

  services.rspamd = {
    enable = true;
    postfix.enable = true;
    locals = {
      "options.inc".text = ''
        dns {
          nameserver = ["127.0.0.1"];
        }
        task_timeout = 15s;
      '';
      "redis.conf".text = ''
        servers = "/run/redis-rspamd/redis.sock";
      '';
    };
  };

  systemd.services.rspamd = {
    after = [ "unbound.service" ];
    requires = [ "unbound.service" ];
  };

  services.redis.servers.rspamd = {
    enable = true;
    group = config.services.rspamd.group;
  };
}
