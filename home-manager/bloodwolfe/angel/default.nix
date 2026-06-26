{ pkgs, ... }: {
  imports = [
    # ../modules
    ../../../hm-modules
  ];
  home.packages = with pkgs; [
    xf86_input_wacom
    wine
    spotify
    wiremix

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
