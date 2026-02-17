{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    asusctl
    powertop
  ];
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start power-state@%E{POWER_SUPPLY_ONLINE}.service"
  '';
  systemd.services."power-state@" =
    let
      power-state = pkgs.writeShellScriptBin "power-state.sh" ''
        set -euo pipefail

        # 1=AC 0=Battery
        STATE="${"1:-"}"

        if [[ "$STATE" == "0" ]]; then

          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver

          for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo powersave > "$gov" 2>/dev/null || true
          done

          if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
              echo 0 > /sys/devices/system/cpu/cpufreq/boost
          fi

          echo powersupersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true

          AMDGPU="/sys/class/drm/card0/device"
          echo auto > "$AMDGPU/power_dpm_force_performance_level" 2>/dev/null || true
          echo low  > "$AMDGPU/power_dpm_state" 2>/dev/null || true

          AMDGPU1="/sys/class/drm/card1/device"
          echo auto > "$AMDGPU1/power_dpm_force_performance_level" 2>/dev/null || true
          echo low  > "$AMDGPU1/power_dpm_state" 2>/dev/null || true

          for f in /sys/module/snd_hda_intel/parameters/power_save; do
            echo 1 > "$f" 2>/dev/null || true
          done

          iw dev wlan0 set power_save on 2>/dev/null || true

          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,2560x1600@60,-2560x0,1"

        else

          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance

          for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo performance > "$gov" 2>/dev/null || true
          done

          if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
            echo 1 > /sys/devices/system/cpu/cpufreq/boost
          fi

          echo performance > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true

          AMDGPU="/sys/class/drm/card0/device"
          echo auto > "$AMDGPU/power_dpm_force_performance_level" 2>/dev/null || true
          echo performance > "$AMDGPU/power_dpm_state" 2>/dev/null || true

          AMDGPU1="/sys/class/drm/card1/device"
          echo auto > "$AMDGPU1/power_dpm_force_performance_level" 2>/dev/null || true
          echo performance > "$AMDGPU1/power_dpm_state" 2>/dev/null || true

          iw dev wlan0 set power_save off 2>/dev/null || true

          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,2560x1600@120,-2560x0,1"

        fi
      '';
    in
    {
      description = "Apply power profile (%i)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${power-state}/bin/power-state.sh %i";
      };
    };
}
