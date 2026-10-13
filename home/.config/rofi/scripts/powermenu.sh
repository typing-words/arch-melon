#!/usr/bin/env bash
# Power menu (rofi, type-4/style-1). Bound to the power key (Fn+Esc) in hyprland.lua.
# Every action except lock asks for confirmation first.

dir="$HOME/.config/rofi/powermenu/type-4"
theme="$dir/style-1.rasi"

uptime=$(uptime -p | sed -e 's/up //g')

# Nerd Font icons
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
# Confirm dialog buttons name the keys that do the same thing: Enter confirms, Esc cancels
yes='ENTER'
no='ESC'

# Only one menu at a time (pressing the key again closes it)
pkill -x rofi && exit 0

confirm() {
    # Row 0 (confirm) is "active" and turns green when selected; row 1 (ESC) is "urgent" and turns red
    choice=$(printf '%s\n%s\n' "$yes" "$no" | rofi -dmenu -a 0 -u 1 \
        -p 'Confirmation' -mesg 'Are you sure?' \
        -theme "$dir/shared/confirm.rasi" \
        -theme-str 'element-text { font: "JetBrainsMono Nerd Font Bold 30"; }' \
        -theme-str 'element selected.active { background-color: #9ECE6A; text-color: var(background); }' \
        -theme-str 'element selected.urgent { background-color: #F7768E; text-color: var(background); }' \
        -theme-str 'message { text-color: var(selected); } textbox { font: "JetBrainsMono Nerd Font Bold 20"; }')
    [ -n "$choice" ] && [ "$choice" = "$yes" ]
}

# Lock option is only shown when hyprlock is installed
options="$suspend\n$logout\n$reboot\n$shutdown"
command -v hyprlock >/dev/null && options="$lock\n$options"

chosen=$(echo -e "$options" | rofi -dmenu \
    -p "Are you leaving?" -mesg "Uptime: $uptime" \
    -theme "$theme" \
    -theme-str 'element { padding: 37px 0px 73px 0px; }')  # feather icons sit low; shift them up to center

# Esc or click outside: do nothing
[ -z "$chosen" ] && exit 0

case $chosen in
    "$shutdown") confirm && systemctl poweroff ;;
    "$reboot")   confirm && systemctl reboot ;;
    "$suspend")  confirm && systemctl suspend ;;
    "$logout")   confirm && loginctl terminate-session "$XDG_SESSION_ID" ;;
    # Wait for rofi to fully close so hyprlock's screenshot background does not include the menu
    "$lock")     sleep 0.5; loginctl lock-session ;;
esac
