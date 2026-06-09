#!/bin/sh
# toggle_screen.sh - 切换屏幕电源开关

BL_POWER="/sys/class/backlight/rk28_bl/bl_power"
POWER_STATE="/sys/class/power_supply/BATTERY/device/state"

current=$(cat "$BL_POWER")

if [ "$current" = "0" ]; then
    echo 4 > "$BL_POWER"
    echo "屏幕已关闭 (bl_power: 0 -> 4)"
elif [ "$current" = "4" ]; then
    echo 0 > "$BL_POWER"
    echo "屏幕已打开 (bl_power: 4 -> 0)"

    CHARGE_STATUS=$(grep -oP 'status\s*=\s*\K\d+' "$POWER_STATE")
    if [ "$CHARGE_STATUS" -eq 1 ]; then
        cpupower frequency-set -g performance >/dev/null 2>&1
        echo "CPU策略: performance (充电中)"
    else
        cpupower frequency-set -g conservative >/dev/null 2>&1
        echo "CPU策略: conservative (电池放电)"
    fi
else
    echo "未知状态: bl_power=$current"
fi

