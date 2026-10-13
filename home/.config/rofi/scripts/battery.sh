#!/usr/bin/env bash
# Battery info applet: adi1090x applet look (applets/type-5/style-1) with the rice
# colors, reading /sys directly instead of acpi. Opened by clicking the Waybar battery.

theme="$HOME/.config/rofi/applets/type-5/battery.rasi"
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)

status=$(<"$bat/status")
capacity=$(<"$bat/capacity")
energy_now=$(<"$bat/energy_now")
energy_full=$(<"$bat/energy_full")
energy_design=$(<"$bat/energy_full_design")
power_now=$(<"$bat/power_now")
cycles=$(<"$bat/cycle_count")

watts=$(awk -v p="$power_now" 'BEGIN { printf "%.1f", p / 1e6 }')
health=$(awk -v f="$energy_full" -v d="$energy_design" 'BEGIN { printf "%d", f * 100 / d }')

# Time left (discharging) or until full (charging), from energy and current draw
if (( power_now > 0 )); then
    case $status in
        Discharging) hours=$(awk -v e="$energy_now" -v p="$power_now" 'BEGIN { print e / p }'); what="left" ;;
        Charging)    hours=$(awk -v e="$energy_now" -v f="$energy_full" -v p="$power_now" 'BEGIN { print (f - e) / p }'); what="until full" ;;
    esac
fi
if [[ -n $hours ]]; then
    time=$(awk -v h="$hours" 'BEGIN { printf "%dh %02dm %s", h, (h - int(h)) * 60, "" }')"$what"
else
    time="Plugged in"
fi

case $capacity in
    [0-9]|1[0-9]) icon="󰁺" ;;
    [2-3][0-9])   icon="󰁼" ;;
    [4-5][0-9])   icon="󰁾" ;;
    [6-7][0-9])   icon="󰂀" ;;
    *)            icon="󰁹" ;;
esac
case $status in
    Charging)    status_icon="󰂄"; status_color="#9ECE6A" ;;
    Discharging) status_icon="󰂃"; status_color="#F7768E" ;;
    *)           status_icon="󰚥"; status_color="#9ECE6A" ;;
esac

printf '%s\n' \
    "<b>$icon  Remaining  $capacity%</b>" \
    "<b>$status_icon  $status</b>" \
    "󱐋  Power draw  $watts W" \
    "󰣐  Health  $health%  ·  󰑓  $cycles cycles" \
| rofi -dmenu -no-custom -markup-rows -u 0 -a 1 \
    -me-accept-entry "" -me-accept-custom "" \
    -mesg "$icon $capacity%, $time" \
    -theme "$theme" \
    -theme-str 'window { width: 640px; border-radius: 16px; }' \
    -theme-str 'imagebox { border-radius: 12px; } inputbar, message, element { border-radius: 10px; }' \
    -theme-str 'listview { columns: 1; lines: 4; }' \
    -theme-str "* { status-color: $status_color; }" \
    -theme-str '* { font: "JetBrainsMono Nerd Font 10"; background: #1A1B26; background-alt: #1F2335; foreground: #C0CAF5; selected: #FF9E64; active: #9ECE6A; urgent: #F7768E; }' \
    >/dev/null
