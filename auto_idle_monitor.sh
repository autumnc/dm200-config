#!/bin/sh
# Auto screen-off after idle timeout + CPU governor based on battery status.
# For ARM device with tmux, terminal-only, no X server.

BACKLIGHT="/sys/class/backlight/rk28_bl/bl_power"
POWER_STATE="/sys/class/power_supply/BATTERY/device/state"
THRESHOLD=300
USER_NAME="root"

# Return the minimum idle seconds across all PTS devices owned by USER_NAME.
# We check both atime (reads, i.e. user typing) and mtime (writes, i.e. shell
# output), taking the later of the two as "last activity" for each PTS.
# Among all user-owned PTS devices, the one with the most recent activity
# determines whether the user is idle — activity in any tmux pane counts.
get_idle_time() {
    now=$(date +%s)
    newest=0
    found=0

    for pts in /dev/pts/*; do
        [ -e "$pts" ] || continue
        [ "$(stat -c %U "$pts" 2>/dev/null)" = "$USER_NAME" ] || continue

        ts=$(stat -c "%X %Y" "$pts" 2>/dev/null)
        atime=${ts%% *}
        mtime=${ts##* }

        last=$atime
        [ "$mtime" -gt "$last" ] && last=$mtime

        [ "$last" -gt "$newest" ] && newest=$last
        found=1
    done

    if [ "$found" -eq 1 ]; then
        echo $((now - newest))
    else
        echo 0
    fi
}

# Return 1 (charging) or 0 (discharging)
get_charge_status() {
    status=$(grep -oP 'status\s*=\s*\K\d+' "$POWER_STATE" 2>/dev/null)
    echo "${status:-0}"
}

while true; do
    IDLE_TIME=$(get_idle_time)
    CHARGE_STATUS=$(get_charge_status)

    if [ "$IDLE_TIME" -ge "$THRESHOLD" ]; then
        echo 4 > "$BACKLIGHT" 2>/dev/null
        cpupower frequency-set -g powersave >/dev/null 2>&1
    else
        echo 0 > "$BACKLIGHT" 2>/dev/null
        if [ "$CHARGE_STATUS" -eq 1 ]; then
            cpupower frequency-set -g performance >/dev/null 2>&1
        else
            cpupower frequency-set -g conservative >/dev/null 2>&1
        fi
    fi

    sleep 15
done
