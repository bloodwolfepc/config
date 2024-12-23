{ config, lib, ... }: {
  config = lib.mkIf (config.specialisation != {}) { 
    boot.postBootCommands = ''
      asusctl profile -P Performance
      powerprofilesctl set performance
    '';
  };
}
