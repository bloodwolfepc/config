{ pkgs, inputs, lib, config, ... }: {
  imports = [ inputs.stylix.nixosModules.stylix ];
  stylix = let
    base16Scheme = {
      base00 = "000000";
      base01 = "1C1C1C";
      base02 = "383838";
      base03 = "545454";
      base04 = "7e7e7e";
      base05 = "a8a8a8"; 
      base06 = "d2d2d2";
      base07 = "fcfcfc";

      base08 = "ff0000";
      base09 = "fbfb40";
      base0A = "ffff00";
      base0B = "00ff00";

      base0C = "00ffff";
      base0D = "0000ff";
      base0E = "ff00ff";
      base0F = "00a800";
    };
  in {
    image = config.wallpaper;
    enable = true;
    autoEnable = true;
    inherit base16Scheme;
    #base16Scheme = "${ pkgs.base16-schemes }/share/themes/windows-95.yaml";
    cursor = {
      package = pkgs.xorg.xcursorthemes; #/share/icons/handhelds
      name = "handhelds";
      size = 23;
    };
    fonts = {
      monospace = {
        package = pkgs.unscii;
        name = "Unscii";
      };
      sansSerif = {
        package = pkgs.unscii;
        name = "Unscii";
      };
      serif = {
        package = pkgs.unscii;
        name = "Unscii";
      }; 
      emoji = {
        package = pkgs.noto-fonts-monochrome-emoji;
        name = "Noto Monochrome Emoji";
      };
    };
    polarity = "dark";   
  };
}
