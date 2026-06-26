{
  pkgs,
  ...
}:
{
  home.persistence = {
    "/persist".directories = [
      ".local/share/zoxide"
      ".config/task"
    ];
  };
  home.packages = with pkgs; [
    bottom
    htop
    dotacat
    bat
    asciiquarium
    gay
    sl
    figlet
    asciicam
    fastfetch
    tree
    ctags
    fzf
    tldr
    jq
    wget
    unzip
    alsa-utils
    taskwarrior-tui
  ];

  programs.fd = {
    enable = true;
  };
  programs.feh = {
    enable = true;
  };
  programs.hyfetch = {
    enable = true;
    settings = {
      backend = "fastfetch";
      pride_month_disable = true;
      preset = "transgender";
      mode = "rgb";
      color_align = {
        mode = "horizontal";
      };
    };
  };
  programs.ripgrep = {
    enable = true;
    package = pkgs.ripgrep-all;
  };
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
  home.shellAliases = {
    z = "cd";
    cat = "dotacat";
    cat-default = "cat";
    slowcat = ''perl -pe "system 'sleep .025'"'';
    scs = "systemctl status";
    scsu = "systemctl status --user";
    jc = "journalctl -xeu";
    jcu = "journalctl --user -xeu";
    zhist = "vi /persist/home/bloodwolfe/.zhistory";
    update-secrets = ''
      cd ~/src/secrets
      git add .
      git commit -m "update-secrets"
      git push
      cd $FLAKE
      nix flake update secrets 
    '';
    td = "task";
    undangle = "find . -xtype l -delete";
    dirty = "watch grep -e Dirty: -e Writeback: /proc/meminfo";
    rsync = "rsync -r --info=progress2 --info=name0";

    ll = "ls -lah";
    la = "ls -A";
    l = "ls -CF";

    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline --graph --decorate --all";

    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
  };

  #programs.atuin = {
  #  enable = true;
  #  settings = {
  #    auto_sync = true;
  #    sync_frequency = "5m";
  #    sync_addresss = "";
  #    search_mode = "prefix";
  #  };
  #};
  # neovim/
  # tmux/
  # yazi/
  # zellij/
  # zsh/
}
