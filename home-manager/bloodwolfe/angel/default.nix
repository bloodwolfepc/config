{
  config,
  inputs,
  pkgs,
  ...
}:
let
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

  home.persistence."/persist".files = [
    ".ssh/id_ed25519_sk_angel"
    ".ssh/id_ed25519_sk_angel.pub"
  ];

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
    editMusic

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
