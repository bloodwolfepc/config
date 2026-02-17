set -euo pipefail

# 1=AC 0=Battery
STATE="${1:-}"

if [[ "$STATE" == "0" ]]; then

  powerprofilesctl set power-saver

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

  hyprctl keyword monitor "eDP-1,2560x1600@60,-2560x0,1"
  # su - bloodwolfe -c "systemctl --user stop kdeconnect.service" || true
  # su - bloodwolfe -c "pkill waybar" || true
else

  powerprofilesctl set performance

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

  hyprctl keyword monitor "eDP-1,2560x1600@120,-2560x0,1"

  # su - bloodwolfe -c "systemctl --user start kdeconnect.service" || true
  # su - bloodwolfe -c "waybar &" || true
fi
