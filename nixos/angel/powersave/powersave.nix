{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.bwcfg.angel.powersave;
in
{
  config = lib.mkIf cfg.enable {
    boot.postBootCommands = ''
      asusctl profile -P Quiet
      powerprofilesctl set power-saver
    '';
    powerManagement.powertop.enable = true;
    environment.etc = {
      "supergfxd.conf" = {
        mode = "0664";
        source = (pkgs.formats.json { }).generate "supergfxd.conf" {
          mode = "Integrated";
          vfio_enable = false;
          vfio_save = false;
          always_reboot = false;
          no_logind = false;
          logout_timeout_s = 180;
          hotplug_type = "None";
        };
      };
    };
  };
}

#(
#    charge_control_end_threshold: 100,
#    panel_od: false,
#    boot_sound: false,
#    mini_led_mode: false,
#    disable_nvidia_powerd_on_battery: true,
#    ac_command: "",
#    bat_command: "",
#    throttle_policy_linked_epp: true,
#    throttle_policy_on_battery: Quiet,
#    change_throttle_policy_on_battery: true,
#    throttle_policy_on_ac: Performance,
#    change_throttle_policy_on_ac: true,
#    throttle_quiet_epp: Power,
#    throttle_balanced_epp: BalancePower,
#    throttle_performance_epp: Performance,
