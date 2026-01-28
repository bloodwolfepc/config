{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    asusctl
    powertop
  ];
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = true;
  # services.udev.extraRules =
  #let
  #  activatePowerSaver = pkgs.writeShellScript "power-save" "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver";
  #  activatePerformance = pkgs.writeShellScript "performance" "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
  #in
  #''
  #  SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="${activatePowerSaver}"
  #  SUBSYSTEM=="power_supply", ATTR{status}=="Charging", RUN+="${activatePerformance}"
  #  SUBSYSTEM=="power_supply", ATTR{status}=="Full", RUN+="${activatePerformance}"

  #     ''
  #       SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="/bin/systemctl start power-state@%E{POWER_SUPPLY_ONLINE}.service"
  #     '';
  #
  #   systemd.services."power-state@" =
  #     let
  #       power-state = pkgs.writeShellScriptBin "power-state.sh" (builtins.readFile ./power-state.sh);
  #     in
  #     {
  #       description = "Apply power profile (%i)";
  #       serviceConfig = {
  #         Type = "oneshot";
  #         ExecStart = "${power-state}/bin/power-state.sh %i";
  #       };
  #     };
}
