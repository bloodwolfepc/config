{
  pkgs,
  ...
}:
{
  imports = [
    ./zsh.nix
    ./neovim.nix
    ./tmux
  ];

  home.persistence = {
    "/sync/home/bloodwolfe".directories = [
      ".config/task"
    ];
    "/persist/home/bloodwolfe".directories = [
      ".local/share/zoxide"
    ];
  };
  home.packages = with pkgs; [
    btop
    htop

    dotacat
    asciiquarium
    gay
    sl
    figlet
    asciicam

    shell-gpt
    aichat

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

  sops.secrets."sgpt-config" = {
    path = "/home/bloodwolfe/.config/shell_gpt/.sgptrc";
  };

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
  };

  programs.yazi = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
  programs.zsh.shellAliases = {
    z = "cd";
  };
}
