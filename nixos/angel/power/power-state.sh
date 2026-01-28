set -euo pipefail

STATE="$1"   # 1 = AC, 0 = Battery

log() { logger -t power-state "$1"; }

if [[ "$STATE" == "0" ]]; then
    log "Switching to BATTERY profile"

    powerprofilesctl set power-saver

    # ---------- CPU ----------
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo powersave > "$gov" 2>/dev/null || true
    done

    # Disable turbo / boost
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo 0 > /sys/devices/system/cpu/cpufreq/boost
    fi

    # ---------- PCIe ASPM ----------
    echo powersupersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true

    # ---------- AMD GPU ----------
    AMDGPU="/sys/class/drm/card0/device"
    echo auto > "$AMDGPU/power_dpm_force_performance_level" 2>/dev/null || true
    echo low  > "$AMDGPU/power_dpm_state" 2>/dev/null || true

    # ---------- Audio power save ----------
    for f in /sys/module/snd_hda_intel/parameters/power_save; do
        echo 1 > "$f" 2>/dev/null || true
    done

    # ---------- WiFi power save ----------
    iw dev wlan0 set power_save on 2>/dev/null || true

    # ---------- Kill heavy user services ----------
    # su - bloodwolfe -c "systemctl --user stop kdeconnect.service" || true
    # su - bloodwolfe -c "pkill waybar" || true


else
    log "Switching to AC profile"

    powerprofilesctl set performance

    # ---------- CPU ----------
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance > "$gov" 2>/dev/null || true
    done

    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo 1 > /sys/devices/system/cpu/cpufreq/boost
    fi

    # ---------- PCIe ----------
    echo default > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true

    # ---------- AMD GPU ----------
    AMDGPU="/sys/class/drm/card0/device"
    echo auto > "$AMDGPU/power_dpm_force_performance_level" 2>/dev/null || true
    echo balanced > "$AMDGPU/power_dpm_state" 2>/dev/null || true

    # ---------- WiFi ----------
    iw dev wlan0 set power_save off 2>/dev/null || true

    # ---------- Restore services ----------
    # su - bloodwolfe -c "systemctl --user start kdeconnect.service" || true
    # su - bloodwolfe -c "waybar &" || true
fi
