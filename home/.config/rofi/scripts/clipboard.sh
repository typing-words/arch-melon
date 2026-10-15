#!/usr/bin/env bash
# Clipboard history (cliphist) in rofi: pick an entry to copy it again.
# Images get a small thumbnail; Alt+P opens the selected image full size in imv.
# Enter = copy, Alt+P = preview image, Alt+Delete = remove entry, Alt+Shift+Delete = clear all history.

theme="$HOME/.config/rofi/launchers/type-2/style-1.rasi"
# Thumbnails next to the history, in RAM (see ~/.config/cliphist/config)
thumbs="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/cliphist/thumbs"
mkdir -p "$thumbs"

# One rofi row per history entry; image entries get their decoded image as the row icon
list() {
    cliphist list | while IFS= read -r line; do
        id=${line%%$'\t'*}
        if [[ $line =~ ^[0-9]+$'\t''[[ binary data '.*' '(png|jpg|jpeg|webp|bmp|gif)' ' ]]; then
            img="$thumbs/$id.${BASH_REMATCH[1]}"
            [ -s "$img" ] || printf '%s' "$line" | cliphist decode > "$img"
            printf '%s\0icon\x1f%s\n' "$line" "$img"
        else
            printf '%s\n' "$line"
        fi
    done
}

while true; do
    choice=$(list | rofi -dmenu -i -no-custom -show-icons \
        -display-columns 2 \
        -kb-custom-1 "Alt+Delete" -kb-custom-2 "Alt+Shift+Delete" -kb-custom-3 "Alt+p" \
        -theme "$theme" \
        -theme-str 'window { width: 600px; } listview { lines: 10; } element-icon { size: 24px; }' \
        -theme-str 'inputbar { children: [ "entry" ]; }')
    status=$?
    case $status in
        0)  [ -n "$choice" ] && printf '%s' "$choice" | cliphist decode | wl-copy; exit ;;
        10) [ -n "$choice" ] && printf '%s' "$choice" | cliphist delete ;;  # back to the list
        12) # Preview the image (if it is one) and come back to the list
            id=${choice%%$'\t'*}
            img=$(ls "$thumbs/$id".* 2>/dev/null | head -n 1)
            [ -n "$img" ] && imv "$img" ;;
        11) cliphist wipe; rm -f "$thumbs"/*; exit ;;
        *)  exit ;;
    esac
done
