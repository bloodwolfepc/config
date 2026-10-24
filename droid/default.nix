{ pkgs, ... }:
let
  angelZellij = pkgs.writeShellApplication {
    name = "angel-zellij";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      exec ssh -t angel zellij attach --create rainbow_session
    '';
  };
  angelMoshZellij = pkgs.writeShellApplication {
    name = "angel-mosh-zellij";
    runtimeInputs = [ pkgs.mosh ];
    text = ''
      exec mosh angel -- zellij attach --create rainbow_session
    '';
  };
in
{
  system.stateVersion = "24.05";
  environment.etcBackupExtension = ".bak";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = "America/Chicago";
  user.shell = "${pkgs.zsh}/bin/zsh";

  android-integration = {
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    config =
      { config, ... }:
      {
        home.stateVersion = "24.05";
        home.packages = with pkgs; [
          age
          angelMoshZellij
          angelZellij
          bat
          curl
          fd
          git
          jq
          jujutsu
          mosh
          neovim
          openssh
          ripgrep
          rsync
          sops
          tree
          yq-go
          zellij
        ];

        home.sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };
        home.shellAliases = {
          vi = "nvim";
          vim = "nvim";
        };

        programs = {
          direnv = {
            enable = true;
            enableZshIntegration = true;
            nix-direnv.enable = true;
          };
          git = {
            enable = true;
            settings = {
              init.defaultBranch = "main";
              user = {
                name = "bloodwolfepc";
                email = "bloodwolfepc@gmail.com";
              };
            };
          };
          ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              default = {
                header = "Host *";
                AddKeysToAgent = "yes";
                ServerAliveInterval = 30;
                ServerAliveCountMax = 3;
              };
              angel = {
                header = "Host angel";
                HostName = "100.64.0.8";
                HostKeyAlias = "angel";
                User = "bloodwolfe";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/angel";
              };
              forgejo = {
                header = "Host forgejo";
                HostName = "100.64.0.9";
                HostKeyAlias = "git.tinywolfe.net";
                Port = 2222;
                User = "git";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/forgejo";
              };
              github = {
                header = "Host github.com";
                User = "git";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/github";
              };
            };
          };
          starship = {
            enable = true;
            enableZshIntegration = true;
          };
          zsh = {
            enable = true;
            autosuggestion.enable = true;
            enableCompletion = true;
            syntaxHighlighting.enable = true;
          };
        };

        home.file = {
          ".ssh/known_hosts.d/angel".text = ''
            angel ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINU+1l0MzwIS056Xilr29bo/14fwRlgcdx4FnMScXcBt
          '';
          ".ssh/known_hosts.d/forgejo".text = ''
            git.tinywolfe.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpOVkRYHUVQngsZsZxYiN2auXnRJtll7IURhUkYMDOH
          '';
          ".ssh/known_hosts.d/github".text = ''
            github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
          '';
          ".config/zellij/config.kdl".source = ../home-manager/bloodwolfe/modules/zellij/config.kdl;
        };
      };
  };
}
