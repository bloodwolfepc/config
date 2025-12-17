{ pkgs, inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  #ssh
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      {
        bits = 4096;
        path = "/persist/system/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/persist/system/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  #sops
  sops =
    let
      secrets = builtins.toString inputs.secrets;
    in
    {
      defaultSopsFile = "${secrets}/secrets/secrets.yaml";
      validateSopsFiles = false;
      defaultSopsFormat = "yaml";
      age = {
        sshKeyPaths = [ "/persist/system/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/persist/system/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
}
