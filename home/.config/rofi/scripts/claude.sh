#!/usr/bin/env bash
# Claude usage applet: shows ~/.local/bin/claude-costs in a read-only rofi list.
# Opened by clicking the Claude pill in Waybar.

summary=$(~/.local/bin/claude-costs)
lines=$(wc -l <<<"$summary")
chars=$(awk '{ if (length > m) m = length } END { print m }' <<<"$summary")

# Header and separator rows can't be selected; the rest only highlight
{
    first=1
    while IFS= read -r line; do
        text=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"$line")
        if (( first )); then
            printf '<b>%s</b>\0nonselectable\x1ftrue\n' "$text"; first=0
        elif [[ $line == ─* ]]; then
            printf '<span foreground="#565f89">%s</span>\0nonselectable\x1ftrue\n' "$text"
        else
            printf '%s\n' "$text"
        fi
    done <<<"$summary"
} | rofi -dmenu -markup-rows -no-custom -p "󰚩 Claude" \
    -mesg "API-price estimate (local data)" \
    -theme "$HOME/.config/rofi/launchers/type-1/style-1.rasi" \
    -theme-str "window { width: calc(${chars}ch + 160px); border-radius: 16px; } listview { columns: 1; lines: $lines; scrollbar: false; } inputbar { enabled: false; }" \
    >/dev/null
