{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  home.packages = with pkgs; [
    sops
    gopass
    bitwarden-desktop
    bitwarden-cli
  ];
  sops = {
    age = {
      keyFile = "/persist${config.home.homeDirectory}/.config/sops/age/key.txt";
    };
    defaultSopsFile = "${builtins.toString inputs.secrets}/secrets/secrets.yaml";
    validateSopsFiles = false;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "main" = {
        host = "gitlab.com";
        identitiesOnly = true;
        identityFile = [
          "${config.home.homeDirectory}/.ssh/gitlab_id_ed25519"
        ];
      };
    };
  };
  sops.secrets = {
    "ssh-angel" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };
    "gitlab_id_ed25519" = {
      path = "${config.home.homeDirectory}/.ssh/gitlab_id_ed25519";
    };
  };

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/src/secrets/password-store";
    };
  };
  services.pass-secret-service = {
    enable = true;
    storePath = "${config.home.homeDirectory}/src/secrets/password-store"; # or ${secrets}/.password-store
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
    userName = "bloodwolfepc";
    userEmail = "bloodwolfepc@gmail.com";
  };
  programs.gh.enable = true;
  sops.secrets."gh-hosts" = {
    path = "/home/bloodwolfe/.config/gh/hosts.yml";
  };

  programs.rbw = {
    enable = true;
  };
}
