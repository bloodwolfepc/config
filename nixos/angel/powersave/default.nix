{ lib, ... }: {
  imports = [
    ./powersave.nix
  ];
  options = {
    bwcfg.angel.powersave = {
      enable = lib.mkEnableOption "Angel powersave.";
    };
  };
}
