#!/usr/bin/env bash
# Emoji picker (rofi-emoji plugin) as a grid of emojis only (theme type-2/style-7).
# Type a name in English to search ("heart", "fire"). Enter types the emoji into the
# focused window and copies it; Alt+1 only copies it.
# Categories: start with @ to limit the search to a group, e.g. "@food pizza" or just "@flag".

# Emoji list without the skin tone variants (2700 of the 5000 rows) and the bare skin tone
# swatches; rebuilt whenever the rofi-emoji package updates its list.
src=/usr/share/rofi-emoji/all_emojis.txt
list="$HOME/.local/share/rofi-emoji/emojis.txt"
if [ ! -s "$list" ] || [ "$src" -nt "$list" ]; then
    mkdir -p "${list%/*}"
    grep -v -e 'skin tone' -e $'\tComponent\t' "$src" > "$list"
fi

# Rofi sizes rows from the font metrics, and the emoji font reports tiny ones (rows came out
# half as tall as the emoji). A normal font gives sane row heights; Pango still draws the
# emoji glyphs from Noto Color Emoji.
rofi -modi emoji -show emoji -emoji-mode insert -emoji-format '{emoji}' -emoji-file "$list" \
    -theme "$HOME/.config/rofi/launchers/type-2/style-7.rasi" \
    -theme-str 'window { width: 560px; }' \
    -theme-str 'listview { columns: 8; lines: 5; spacing: 4px; scrollbar: true; flow: horizontal; }' \
    -theme-str 'element { padding: 8px 0px; border-radius: 10px; }' \
    -theme-str 'element-icon { enabled: false; }' \
    -theme-str 'element-text { font: "JetBrainsMono Nerd Font 22"; horizontal-align: 0.5; vertical-align: 0.5; }' \
    -theme-str 'inputbar { children: [ "entry" ]; }'
