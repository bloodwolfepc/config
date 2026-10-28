{
  config,
  pkgs,
  ...
}:
{
  # imports = [
  #   inputs.sops-nix.homeManagerModules.sops
  # ];
  home.packages = with pkgs; [
    sops
    gopass
  ];
  sops.age.keyFile = "/persist${config.home.homeDirectory}/.config/sops/age/key.txt";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      github = {
        header = "Host github.com";
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = [
          "${config.home.homeDirectory}/.ssh/id_ed25519_sk_angel"
        ];
      };
      gitlab = {
        header = "Host gitlab.com";
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = [
          "${config.home.homeDirectory}/.ssh/id_ed25519_sk_angel"
        ];
      };
      forgejo = {
        header = "Host forgejo";
        HostName = "srv-vm.srvctl.ts.net";
        HostKeyAlias = "git.tinywolfe.net";
        Port = 2222;
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = [
          "${config.home.homeDirectory}/.ssh/id_ed25519_sk_angel"
        ];
      };
      admin-vm = {
        header = "Host admin-vm admin-vm.srvctl.ts.net";
        HostName = "admin-vm.srvctl.ts.net";
        HostKeyAlias = "admin-vm";
        StrictHostKeyChecking = "yes";
        UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/admin-vm";
      };
      admin-vm-lan = {
        header = "Host admin-vm-lan";
        HostName = "192.168.5.4";
        HostKeyAlias = "admin-vm";
        StrictHostKeyChecking = "yes";
        UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/admin-vm";
      };
      srv-vm = {
        header = "Host srv-vm srv-vm.srvctl.ts.net";
        HostName = "srv-vm.srvctl.ts.net";
        HostKeyAlias = "srv-vm";
        StrictHostKeyChecking = "yes";
        UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/srv-vm";
      };
      navi = {
        header = "Host navi";
        HostName = "tinywolfe.net";
        RemoteForward = "127.0.0.1:2489 127.0.0.1:2489";
      };
      navi-hostnames = {
        header = "Host navi.srvctl.ts.net tinywolfe.net";
        RemoteForward = "127.0.0.1:2489 127.0.0.1:2489";
      };
    };
  };

  home.file = {
    ".ssh/known_hosts.d/admin-vm".text = ''
      admin-vm ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5usOlyWjopfqK4XocBSTtztxSin0taRIiwhy7F/Eg5
    '';
    ".ssh/known_hosts.d/srv-vm".text = ''
      srv-vm ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACFW/KSvimD8k8SnBJuyCuN8aq6csMUqRrPxfbLRpL2
    '';
  };

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    enableScDaemon = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-tty;
    verbose = true;
  };
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    mutableKeys = false;
    mutableTrust = false;
    publicKeys = [
      {
        source = ./B74857A702B0C92B-2024-04-15.asc;
        trust = 5;
      }
    ];
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "bloodwolfepc";
        email = "bloodwolfepc@gmail.com";
      };
    };
  };
  programs.gh.enable = true;
}
