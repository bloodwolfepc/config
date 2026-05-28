{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    asusctl
    powertop
  ];
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = true;
  environment.etc."power/power-state.sh" = {
    text = (builtins.readFile ./power-state.sh);
    mode = "0755";
  };
  # services.udev.extraRules = ''
  #   SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", \
  #     RUN+="${pkgs.systemd}/bin/systemctl start power-state@%E{POWER_SUPPLY_ONLINE}.service"
  # '';
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", \
      TAG+="systemd", \
      ENV{SYSTEMD_WANTS}="power-state@%E{POWER_SUPPLY_ONLINE}.service"
  '';
  systemd.services."power-state@" = {
    description = "Apply power profiles (%i)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/power/power-state.sh %i";
    };
  };
}
