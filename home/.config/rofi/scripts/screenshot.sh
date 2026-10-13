#!/usr/bin/env bash
# Screenshot applet: adi1090x applet look (applets/type-3/style-1, icons only),
# rewritten for Wayland with hyprshot + satty instead of maim/xclip.

theme="$HOME/.config/rofi/applets/type-3/style-1.rasi"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"

# Feather font icons, same as the original applet (annotate uses its "editor" icon)
option_1=$'\ue9a2'   # Capture Desktop
option_2=$'\ue952'   # Capture Area
option_3=$'\ue988'   # Capture Window
option_4=$'\ue95b'   # Capture Area + Annotate
option_5=$'\uea0d'   # Capture in 5s
option_6=$'\ue939'   # Capture in 10s

chosen=$(printf '%s\n' "$option_1" "$option_2" "$option_3" "$option_4" "$option_5" "$option_6" \
    | rofi -dmenu -no-custom \
        -p "Screenshot" \
        -theme "$theme" \
        -theme-str 'window { width: 120px; }' \
        -theme-str 'listview { columns: 1; lines: 6; }' \
        -theme-str 'textbox-prompt-colon { str: ""; }')

countdown() {
    for sec in $(seq "$1" -1 1); do
        notify-send -t 1000 -h string:x-canonical-private-synchronous:shot "Taking shot in: $sec"
        sleep 1
    done
}

# Let rofi close before capturing so it doesn't show up in the shot
sleep 0.2

case "$chosen" in
    "$option_1") hyprshot -m output -m active -o "$dir" ;;
    "$option_2") hyprshot -z -m region -o "$dir" ;;
    "$option_3") hyprshot -m window -o "$dir" ;;
    "$option_4") hyprshot -z -m region -r | satty --filename - --early-exit --copy-command wl-copy \
                     --output-filename "$dir/satty-%Y%m%d-%H%M%S.png" ;;
    "$option_5") countdown 5;  hyprshot -m output -m active -o "$dir" ;;
    "$option_6") countdown 10; hyprshot -m output -m active -o "$dir" ;;
esac
