#!/usr/bin/env bash
# Window switcher: every open window on every workspace, with its app icon.
# Type to filter by app or title, Enter jumps to it.

rows=$(mktemp)
trap 'rm -f "$rows"' EXIT

# One row per window: address (hidden) <tab> workspace, app, title; the app icon comes from its class
hyprctl clients -j | jq -r '
    [.[] | select(.mapped and .workspace.id > 0)] | sort_by(.workspace.id, .focusHistoryID) | .[] |
    "\(.address)\t\(.workspace.id)  \(.class | split(".") | last)  ·  \(.title)\u0000icon\u001f\(.class)"' > "$rows"
[ -s "$rows" ] || exit 0

choice=$(rofi -dmenu -i -p " Windows" -no-custom -show-icons \
    -display-columns 2 -format i \
    -theme "$HOME/.config/rofi/launchers/type-1/style-5.rasi" \
    -theme-str 'element-icon { size: 24px; }' \
    -theme-str 'inputbar { children: [ "entry" ]; } entry { placeholder: "Search windows..."; }' < "$rows") || exit 0

address=$(sed -n "$((choice + 1))p" "$rows" | cut -f1)
hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
