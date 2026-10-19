#!/usr/bin/env bash
# Opens the app launcher (apps.sh) with the type-3/style-2 theme.
# Uses one column per app (up to 10) so a short list spreads across the screen centered.
# Dark tinted background (plus Hyprland blur) so text stays readable over light windows.
# The app list is built only once and handed to apps.sh through APPS_LIST.

scripts="$HOME/.config/rofi/scripts"
export APPS_LIST="${XDG_RUNTIME_DIR:-/tmp}/rofi-apps.list"
APPS_LIST='' "$scripts/apps.sh" > "$APPS_LIST"   # empty: apps.sh builds the list
count=$(tail -n +2 "$APPS_LIST" | wc -l)
columns=$(( count < 1 ? 1 : (count > 10 ? 10 : count) ))

rofi -show apps \
    -modi "apps:$scripts/apps.sh" \
    -display-apps "" \
    -theme "$HOME/.config/rofi/launchers/type-3/style-2.rasi" \
    -theme-str "listview { columns: $columns; } window { background-color: black / 60%; }"
