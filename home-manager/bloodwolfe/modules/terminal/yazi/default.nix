{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nerd-fonts.noto
    ffmpeg_7
    p7zip
    poppler
    resvg
    imagemagick

    jq
    fd
    ripgrep
    fzf
    zoxide
  ];
  programs.zsh.shellAliases = {
    ff = "yazi";
  };
  programs.yazi = {
    enable = true;
    package = pkgs.yazi.override {
      _7zz = pkgs._7zz-rar;
    };
    enableZshIntegration = true;
    extraPackages = with pkgs.yaziPlugins; [
      git
      sudo
      ouch
      glow
    ];
    settings = {
      mgr = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "natural";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_hidden = true;
        show_symlink = true;
      };
      preview = {
        image_filter = "lanczos3";
        image_quality = 90;
        tab_size = 1;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        ueberzug_scale = 1;
        ueberzug_offset = [
          0
          0
          0
          0
        ];
      };
      tasks = {
        micro_workers = 5;
        macro_workers = 10;
        bizarre_retry = 5;
      };
    };
  };

  xdg = {
    portal = {
      enable = true;
      xdgOpenUsePortal = false;
      extraPortals = with pkgs; [
        xdg-desktop-portal-termfilechooser
      ];
      config = {
        common = {
          default = [
            "termfilechooser"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        };
        hyprland = {
          default = [
            "termfilechooser"
            "wlr"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        };
      };
    };
    configFile =
      let
        yazi-wrapper = pkgs.writeShellScriptBin "yazi-wrapper.sh" (builtins.readFile ./yazi-wrapper.sh);
      in
      {
        "xdg-desktop-portal-termfilechooser/config" = {
          text = ''
            [filechooser]
            cmd=${yazi-wrapper}/bin/yazi-wrapper.sh
            default_dir=$XDG_DOWNLOAD_DIR
          '';
        };
      };
  };
}
