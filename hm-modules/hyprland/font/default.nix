{ pkgs, ... }:
{
  home.packages = with pkgs; [
    unscii
    nerd-fonts.symbols-only
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ ];
    };
    configFile = {
      main = {
        enable = true;
        priority = 90;
        text = ''
          <match target="scan">
            <test name="fullname" compare="eq">
              <string>unscii-16-full</string>
            </test>

            <edit name="family" mode="assign_replace">
              <string>helloworld</string>
            </edit>
          </match>
        '';
      };
    };
  };
}
