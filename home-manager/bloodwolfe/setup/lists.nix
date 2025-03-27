{ lib, ... }: {
  options.globals.list = {
    require-nixos = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    require-hm = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    require-pc = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    srv-progs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    used-progs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    gaming-progs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    workstation-progs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    unused-progs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
  }; 
  config = {
    globals = {
      list = {
        require-nixos = [
          "impermanence"
          "ssh"
          "syncthing"
          "ripgrep"
          "src"
          "gpg"
          "sops"
        ];
        require-hm = [
          "thefuck"
          "tmux"
          "zoxide"
          "zsh"
          "neovim"
          "btop"
          "git"
          "htop"
          "hyfetch"
          "fd"
          "yazi"
          "nh"
          #"staging"
          "stylix"
        ];
        require-pc = [
          "hyprland"
          #"rofi"
          "tofi"
          "swaync"
          "waybar"
          "xdg"
          "lxqt-policykit"
          "cliphist"
          "wireplumber"
          "fcitx5"
          "wezterm"
          "alacritty"
          "xdg"
        ];
        srv-progs = [
          "qemu"
          "podman"
          "virt-manager"
        ];
        used-progs = [
          "kdeconnect"
          "sgpt"
          "feh"
          #"nix-serv"
          "nix-index"
          "appimages"
          "flatpak"
          "library"
          "notebook"
          "spotify"
          "spotify-player"
          "taskwarrior"
          "xournalpp"
          "zathura"
          "qutebrowser"
          "firefox"
          "mpv"
          "mpd"
          "vesktop"
          "khal"
          "terminal-extras"
        ];
        gaming-progs = [
          "mangohud"
          "prismlauncher"
          "steam"
          "retroarch"
          #"wl-crosshair"
        ];
        #games = [
        #  "techmino"
        #];
        workstation-progs = [
          "beeref"
          "bevy"
          "blender"
          "daw"
          "gimp"
          "krita"
          "obs"
          "pixelorama"
          "olive-editor"
          "godot"
          "freecad"
        ];
        unused-progs = [
          "bitwarden"
          "lf" 
          "qutebrowser"
          "kdenlive"
          "libreoffice"
          "msmtp"
          "neomutt"
          "pass"
          "libresprite"
        ];
      };
    };
  };
}
