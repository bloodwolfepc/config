{ pkgs, config, lib, inputs, ... }: {
  containers.waterdreamer = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "10.10.11.2";
    localAddress = "10.10.10.2";
    config = { pkgs, ... }: {
      system.stateVersion = "24.05";
      networking = {
        firewall = { enable = true; allowedTCPPorts = [
          80 443
        ];
      };
      useHostResolvConf = lib.mkForce false;
      };
      services.resolved.enable = true;
      security.acme = {
        acceptTerms = true;
        defaults.email = "bloodwolfepc@gmail.com";
      };
      #systemd.services.nginx = {
      #  after = [ "acme-waterdreamer.net.service" ];
      #};
      systemd.services."acme-waterdreamer.net" = {
        after = [ "nginx.service" ];
      };
      services.nginx = {
        enable = true;
        virtualHosts."waterdreamer.net" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = { #idk html look away
            return = ''
            200 '
              <html>
                <br>
                <body style="background-color: black; color: #00ffff;">
                  connection to waterdreamer.net: 
                </body>
                <br> <br>
                <body2 style="color:#ff00ff;">
                  BIO: <br>
                  twin cities mn, <br>
                  crow.wav <br>
                </body2>
                <br> <br> <br>
                <body3 style="color:lightgrey;">
                  <a style="color:lightgrey;"href="bloodwolfepc@gmail.com">bloodwolfepc@gmail.com</a>
                </body3>
                <br>
                <body4 style="color:gold;">
                  PGP: <a style="color:cyan;"href="https://raw.githubusercontent.com/bloodwolfepc/flake/06df42c71a96e2b7387fffbc5344efce5fe0ab45/home-manager/bloodwolfe/modules/require/gpg/B74857A702B0C92B-2024-04-15.asc">1616 47C1 14E2 1F60 A186  E252 B748 57A7 02B0 C92B</a>
                </body4>
                <br> <br> <br> <br> <br> <br> <br>
                <body5 style="color: #594b80;">
                  <a href="https://github.com/bloodwolfepc">git</a> - 
                  <a href="https://x.com/bloodwolfepc">twitter</a> - 
                  <a href="https://bsky.app/profile/bloodwolfepc.bsky.social">bluesky</a>
                  <a href="https://www.last.fm/user/bedwolfe">lfm</a> - 
                  <a href="https://rateyourmusic.com/~bloodwolfepc">rym</a> - 
                  <a href="https://letterboxd.com/evilcatlawyer/">letterboxd</a>
                </body5>
              </html>
              '
            '';
            extraConfig = ''
              default_type text/html;
            '';
          };
        };
      };
    };
  };
}

