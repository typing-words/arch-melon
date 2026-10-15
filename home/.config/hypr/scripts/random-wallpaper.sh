#!/usr/bin/env bash
# Picks a random wallpaper from ~/Pictures/Wallpapers for each monitor (via awww).
# Runs once at Hyprland start, so wallpapers stay the same until the next login.
# Works like a shuffled deck: no image repeats (across monitors or logins) until
# every one has been shown; then the deck is shuffled again.

dir="$HOME/Pictures/Wallpapers"

# Start the awww daemon if it isn't running yet, and wait until it answers
pgrep -x awww-daemon >/dev/null || (awww-daemon >/dev/null 2>&1 &)
for _ in $(seq 50); do awww query >/dev/null 2>&1 && break; sleep 0.1; done

mapfile -t images < <(find "$dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \))
[ ${#images[@]} -eq 0 ] && exit 0

# Images not shown yet, one path per line (files deleted since are skipped)
deck="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-deck"
mkdir -p "$(dirname "$deck")"
next_image() {
    local image
    while :; do
        [ -s "$deck" ] || printf '%s\n' "${images[@]}" | shuf > "$deck"
        image=$(head -n 1 "$deck")
        sed -i 1d "$deck"
        [ -f "$image" ] && { echo "$image"; return; }
    done
}

for monitor in $(hyprctl monitors -j | python3 -c 'import json,sys; print(" ".join(m["name"] for m in json.load(sys.stdin)))'); do
    awww img -o "$monitor" "$(next_image)" --transition-type fade --transition-duration 1
done
