#!/usr/bin/env bash
# Picks a random wallpaper from ~/Pictures/Wallpapers for each monitor (via awww).
# Runs once at Hyprland start, so wallpapers stay the same until the next login.

dir="$HOME/Pictures/Wallpapers"

# Start the awww daemon if it isn't running yet, and wait until it answers
pgrep -x awww-daemon >/dev/null || (awww-daemon >/dev/null 2>&1 &)
for _ in $(seq 50); do awww query >/dev/null 2>&1 && break; sleep 0.1; done

mapfile -t images < <(find "$dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \))
[ ${#images[@]} -eq 0 ] && exit 0

for monitor in $(hyprctl monitors -j | python3 -c 'import json,sys; print(" ".join(m["name"] for m in json.load(sys.stdin)))'); do
    image=${images[RANDOM % ${#images[@]}]}
    awww img -o "$monitor" "$image" --transition-type fade --transition-duration 1
done
