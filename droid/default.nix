{ pkgs, ... }:
let
  sharedStarshipConfig = ./shared/starship.toml;
  sharedZellijConfig = ./shared/zellij.kdl;
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
  adminZellij = pkgs.writeShellApplication {
    name = "admin-zellij";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      host=admin-vm
      if ssh -o BatchMode=yes -o ConnectTimeout=3 admin-vm-direct true 2>/dev/null; then
        host=admin-vm-direct
      fi
      exec ssh -t "$host" admin-zellij
    '';
  };
  adminMoshZellij = pkgs.writeShellApplication {
    name = "admin-mosh-zellij";
    runtimeInputs = [ pkgs.mosh ];
    text = ''
      exec mosh admin-vm-direct -- admin-zellij
    '';
  };
  phoneConfigSync = pkgs.writeShellApplication {
    name = "phone-config-sync";
    runtimeInputs = [ pkgs.git ];
    text = ''
      repo="$HOME/src/config"
      if [[ -d "$repo/.git" ]]; then
        git -C "$repo" pull --ff-only
      elif [[ -e "$repo" ]]; then
        echo "$repo exists but is not a Git checkout" >&2
        exit 1
      else
        mkdir -p "$(dirname "$repo")"
        git clone https://github.com/bloodwolfepc/config.git "$repo"
      fi
      exec nix-on-droid switch --flake "$repo/droid#phone"
    '';
  };
  phoneEnroll = pkgs.writeShellApplication {
    name = "phone-enroll";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      key="$HOME/.ssh/id_ed25519_phone"
      install -d -m 0700 "$HOME/.ssh"
      if [[ ! -e "$key" && ! -e "$key.pub" ]]; then
        ssh-keygen -t ed25519 -a 100 -C tinywolfe-android -f "$key"
      elif [[ ! -f "$key" || ! -f "$key.pub" ]]; then
        echo "incomplete phone SSH keypair at $key" >&2
        exit 1
      fi
      cat "$key.pub"
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
      {
        config,
        lib,
        ...
      }:
      {
        home.stateVersion = "24.05";
        home.packages = with pkgs; [
          adminMoshZellij
          adminZellij
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
          phoneConfigSync
          phoneEnroll
          ripgrep
          rsync
          sops
          tree
          yq-go
          zellij
        ];

        home.sessionVariables = {
          EDITOR = "nvim";
          SHELL = "${pkgs.zsh}/bin/zsh";
          STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
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
              admin-vm = {
                header = "Host admin-vm";
                HostName = "192.168.5.4";
                HostKeyAlias = "admin-vm";
                ProxyJump = "navi";
                User = "mobiledev";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/admin-vm";
              };
              admin-vm-direct = {
                header = "Host admin-vm-direct";
                HostName = "admin-vm.srvctl.ts.net";
                HostKeyAlias = "admin-vm";
                User = "mobiledev";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/admin-vm";
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
              navi = {
                header = "Host navi";
                HostName = "100.64.0.4";
                HostKeyAlias = "navi";
                User = "bloodwolfe";
                IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519_phone" ];
                IdentitiesOnly = true;
                StrictHostKeyChecking = "yes";
                UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/navi";
              };
            };
          };
          starship = {
            enable = true;
            enableZshIntegration = true;
          };
          zoxide = {
            enable = true;
            enableZshIntegration = true;
          };
          zsh = {
            enable = true;
            autosuggestion.enable = true;
            enableCompletion = true;
            syntaxHighlighting.enable = true;
            initContent = lib.mkAfter ''
              if [[ -o interactive && -z "''${ZELLIJ:-}" && "''${ZELLIJ_AUTO_ATTACH:-1}" == 1 ]]; then
                zellij attach --create phone
              fi
            '';
          };
        };

        home.file = {
          ".config/starship.toml".source = sharedStarshipConfig;
          ".config/zellij/config.kdl".source = sharedZellijConfig;
          ".ssh/known_hosts.d/admin-vm".text = ''
            admin-vm ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5usOlyWjopfqK4XocBSTtztxSin0taRIiwhy7F/Eg5
          '';
          ".ssh/known_hosts.d/angel".text = ''
            angel ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINU+1l0MzwIS056Xilr29bo/14fwRlgcdx4FnMScXcBt
          '';
          ".ssh/known_hosts.d/forgejo".text = ''
            git.tinywolfe.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpOVkRYHUVQngsZsZxYiN2auXnRJtll7IURhUkYMDOH
          '';
          ".ssh/known_hosts.d/github".text = ''
            github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
          '';
          ".ssh/known_hosts.d/navi".text = ''
            navi ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQ52guuLRczgvdymn9TgXVXo5hUBXD2/GsVa0h7kHeS
          '';
        };
      };
  };
}
