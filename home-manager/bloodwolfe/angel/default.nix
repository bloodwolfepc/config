{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  signingPublicKey = lib.trim (builtins.readFile ./id_ed25519_sk_angel.pub);
  allowedSigners = pkgs.writeText "git-allowed-signers" ''
    bloodwolfepc@gmail.com namespaces="git" ${signingPublicKey}
  '';
  gitPrePush = pkgs.writeShellApplication {
    name = "git-pre-push";
    runtimeInputs = [ pkgs.git ];
    text = ''
      zero=0000000000000000000000000000000000000000
      while read -r _local_ref local_sha remote_ref remote_sha; do
        [[ "$remote_ref" == refs/heads/main || "$remote_ref" == refs/heads/master ]] || continue
        [[ "$local_sha" != "$zero" ]] || {
          echo "refusing to delete protected branch $remote_ref" >&2
          exit 1
        }
        if [[ "$remote_sha" != "$zero" ]]; then
          git merge-base --is-ancestor "$remote_sha" "$local_sha" || {
            echo "refusing non-fast-forward promotion to $remote_ref" >&2
            exit 1
          }
          range="$remote_sha..$local_sha"
        else
          range="$local_sha"
        fi
        while read -r commit; do
          git verify-commit "$commit" >/dev/null 2>&1 || {
            echo "unsigned or untrusted commit $commit cannot be promoted to $remote_ref" >&2
            echo "squash reviewed topic work, then use git scommit" >&2
            exit 1
          }
        done < <(git rev-list --reverse "$range")
      done
    '';
  };
  documentsVault = pkgs.writeShellApplication {
    name = "documents-vault";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.fuse3
      pkgs.gocryptfs
      pkgs.util-linux
    ];
    text = ''
      set -euo pipefail
      cipher="$HOME/nextcloud/documents-vault"
      mount="$HOME/secure-documents"
      case "''${1:-status}" in
        init)
          install -d -m 0700 "$cipher" "$mount"
          [[ -z "$(find "$cipher" -mindepth 1 -print -quit)" ]] || {
            echo "refusing to initialize non-empty $cipher" >&2
            exit 1
          }
          gocryptfs -init "$cipher"
          printf 'Store the printed master key offline before adding real documents.\n'
          ;;
        open)
          [[ -f "$cipher/gocryptfs.conf" ]] || {
            echo "initialize the vault first: documents-vault init" >&2
            exit 1
          }
          install -d -m 0700 "$mount"
          ! mountpoint --quiet "$mount" || { echo "$mount is already open" >&2; exit 1; }
          gocryptfs "$cipher" "$mount"
          ;;
        close)
          mountpoint --quiet "$mount" || { echo "$mount is already closed"; exit 0; }
          fusermount3 -u "$mount"
          ;;
        status)
          if mountpoint --quiet "$mount"; then
            echo "open: $mount"
          else
            echo "closed: ciphertext is in $cipher"
          fi
          ;;
        *) echo 'usage: documents-vault {init|open|close|status}' >&2; exit 2 ;;
      esac
    '';
  };
  editMusic = pkgs.writeShellApplication {
    name = "edit-music";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      target=bloodwolfe@srv-vm.srvctl.ts.net
      theme="$HOME/.config/starship.toml"
      [[ -r "$theme" ]] || { echo "missing Starship config: $theme" >&2; exit 1; }
      ssh "$target" srv-compose --services-root /etc/srv/services/arr \
        exec -T music-editor tee /config/starship.toml <"$theme" >/dev/null
      exec ssh -t "$target" srv-compose --services-root /etc/srv/services/arr \
        exec music-editor zsh -l
    '';
  };
in
{
  imports = [
    ../modules
    ../modules/audio
    ../modules/bitwarden
  ];
  dotfiles.mutable = true;

  sops = {
    defaultSopsFile = "${inputs.secrets}/sops/users/bloodwolfe/angel.yaml";
    secrets."ssh-angel".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
  };

  home.persistence."/persist".directories = [
    ".config/Nextcloud"
    ".local/share/keyrings"
    "nextcloud"
  ];
  home.persistence."/persist".files = [
    ".ssh/id_ed25519_sk_angel"
    ".ssh/id_ed25519_sk_angel.pub"
  ];

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  programs.git.settings = {
    alias.scommit = "commit -S";
    commit.gpgSign = false;
    gpg = {
      format = "ssh";
      ssh.allowedSignersFile = "${allowedSigners}";
    };
    tag.forceSignAnnotated = true;
    user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_angel";
  };

  home.activation.gitPromotionHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for repo in "$HOME/src/config" "$HOME/src/srv"; do
      if [[ -d "$repo/.git/hooks" ]]; then
        run ln -sfn ${gitPrePush}/bin/git-pre-push "$repo/.git/hooks/pre-push"
      fi
    done
  '';

  systemd.user.services.lemonade = {
    Unit = {
      Description = "Local clipboard bridge for SSH sessions";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lemonade}/bin/lemonade server --allow=127.0.0.1,::1";
      Environment = "PATH=${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.wl-clipboard
        ]
      }";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = with pkgs; [
    xf86_input_wacom
    wine
    wiremix
    ego
    documentsVault
    editMusic
    gocryptfs
    nextcloud-client
    sirikali

    (writeShellScriptBin "ddc-default" ''
      ddcutil setvcp 10 45
      ddcutil setvcp 87 50
    '')
    (writeShellScriptBin "ddc-comp" ''
      ddcutil setvcp 10 100
      ddcutil setvcp 87 70
    '')
  ];
}
