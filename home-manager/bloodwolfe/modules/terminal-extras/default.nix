{
  lib,
  config,
  pkgs,
  outputs,
  ...
}:
let
  attrs = lib.custom.mkHomeApplication {
    name = "terminal-extras";
    packages =
      with pkgs;
      [
        #lolcat
        dotacat

        #lolcrab
        figlet
        sl
        #cowsay
        asciiquarium
        gay
        neofetch
        #https://github.com/poetaman/arttime

        catimg
        jp2a
        ascii-image-converter
        goat # convert to svg diagrams

        era
        tenki
        rsclock # clock-rs
        tty-clock

        bat
        viddy
        moar
        toolong
        dust
        ncdu
        eza

        bsdgames
        nbsdgames

        unimatrix
        cmatrix
        tmatrix
        neo

        pipes-rs # pipes

        libresprite
        #aseprite

        ascii-draw

        #nyancat

        #fortune
        #fortune-kind
        #taoup

        asciicam

        glances
        gtop
        curlie

        #wakatime

        openpomodoro-cli
        termdown
        #others:
        #https://kevinschoon.github.io/pomo/ cmd support
      ]
      ++ (with outputs.customPackages; [
        ascii-rain
        durdraw
        #clock-tui
        #https://github.com/puyral/custom-nix/blob/0ac49ab66662db2af076dcb6fdfe8db7b7d31917/apackages/tclock.nix#L5
      ]);
    programs = {
      irssi = {
        enable = false;
        networks = {
          liberachat = {
            nick = "bwtestuser";
            server = {
              address = "irc.libera.chat";
              port = 6697;
              autoConnect = true;
            };
          };
          channels = {
            nixos.autoJoin = true;
            tmux.autoJoin = true;
          };
        };
      };
      newsboat = {
        enable = true;
        autoReload = true;
        urls =
          let
            mkSource = tags: url: { inherit tags url; };
          in
          [
            (mkSource [ "tech" ] "https://xeiaso.net/blog.rss")
            (mkSource [ "tech" ] "https://100r.co/links/rss.xml")
            (mkSource [ "tech" ] "https://catgirl.ai/log/atom.xml")

            (mkSource [ "news" ] "https://feeds.npr.org/1001/rss.xml")
            (mkSource [ "tech" ] "https://www.phoronix.com/rss.php")
            (mkSource [ "tech" ] "http://www.linux.com/feeds/all-content")
            (mkSource [ "tech" ] "https://www.cyberciti.com/atom/atom.xml")
            (mkSource [ "tech" ] "https://frame.work/blog.rss")

            (mkSource [ "tech" ] "https://hnrss.org/frontpage")
            (mkSource [ "tech" ] "https://www.reddit.com/r/linux/.rss")
            (mkSource [ "tech" ] "https://www.reddit.com/r/neovim/.rss")
            (mkSource [ "tech" ] "https://discourse.nixos.org/c/announcements/8.rss")
            (mkSource [ "tech" ] "https://github.com/NixOS/nixpkgs/commits/master.atom")

            (mkSource [ "sites" ] "https://neocities.org/site/starbage.rss")
          ];
      };
    };
    home.file = {
      ".pomodoro/hooks/start" = {
        text = builtins.readFile ./start.sh;
        executable = true;
      };
      ".pomodoro/hooks/stop" = {
        text = builtins.readFile ./stop.sh;
        executable = true;
      };
      ".pomodoro/hooks/break" = {
        text = builtins.readFile ./break.sh;
        executable = true;
      };
    };
    home.shellAliases = {
      tt = "pomodoro -f '%!r🐺 %c%!g🐺%d%t'";
    };
    persistFiles = [
      ".pomodoro/history"
    ];
    inherit config;
  };
in
{
  inherit (attrs) options config;
}
