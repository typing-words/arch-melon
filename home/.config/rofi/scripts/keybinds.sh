#!/usr/bin/env bash
# Shows all Hyprland keybinds (read live from hyprctl), grouped by category, in rofi.

rows=$(mktemp)
trap 'rm -f "$rows"' EXIT

hyprctl binds -j | python3 -c '
import json, sys, html, re
seen = set()
mods = [(64, "Super"), (4, "Ctrl"), (8, "Alt"), (1, "Shift")]
keys = {"mouse:272": "Hold left click", "mouse:273": "Hold right click",
        "mouse_down": "Mouse wheel down", "mouse_up": "Mouse wheel up",
        "RETURN": "Enter", "SPACE": "Space",
        "left": "Left", "right": "Right", "up": "Up", "down": "Down",
        "XF86PowerOff": "Power key", "ESCAPE": "Esc", "TAB": "Tab", "EQUAL": "=", "MINUS": "-"}
# Submap name -> the bind that enters it
submaps = {"apps": "Super + Space"}
# First matching keyword (in the description) decides the category
categories = [
    ("Screenshots", ["screenshot", "record"]),
    ("Tools",       ["clipboard", "emoji", "color", "keybinds", "ocr", "magnifier"]),
    ("Workspaces",  ["workspace", "scratchpad"]),
    ("Windows",     ["window", "focus", "pseudo", "split", "gaps"]),
    ("Apps",        ["email", "browser", "terminal", "file manager", "launcher"]),
    ("System",      [""]),
]
order = ["Apps", "Windows", "Workspaces", "Screenshots", "Tools", "System", "Clipboard"]
groups = {name: [] for name, _ in categories}
for b in json.load(sys.stdin):
    # Hide submap plumbing (entry bind and catch-all exit)
    if b["catch_all"] or b["description"].endswith("submap"):
        continue
    # Hide special keys that just do what is printed on them (volume, brightness, media, calculator...);
    # keep the power key, which opens a menu
    if b["key"].startswith("XF86") and b["key"] != "XF86PowerOff":
        continue
    combo = [name for bit, name in mods if b["modmask"] & bit]
    key = keys.get(b["key"], b["key"].replace("XF86", "").replace("Audio", "Audio ").replace("MonBrightness", "Brightness "))
    combo.append(key.upper() if len(key) == 1 else key)
    combo = " + ".join(combo)
    if b["submap"]:
        combo = submaps.get(b["submap"], b["submap"]) + ", " + combo
    desc = b["description"] or b["dispatcher"]
    # Collapse the four arrow binds of each kind into one row: Super + [Arrows]
    if b["key"] in ("left", "right", "up", "down") and desc.endswith(" " + b["key"]):
        combo = combo.rsplit(" + ", 1)[0] + " + [Arrows]"
        desc = desc[: -len(b["key"])] + "[arrow] direction"
        if (combo, desc) in seen:
            continue
        seen.add((combo, desc))
    # Collapse the ten workspace binds of each kind into one row: Super + [0-9]
    m = re.fullmatch(r"(.+ workspace) (\d+)", desc)
    if m and b["key"].isdigit():
        combo = combo.rsplit(" + ", 1)[0] + " + [0-9]"
        desc = m.group(1) + " (0 = 10)"
        if (combo, desc) in seen:
            continue
        seen.add((combo, desc))
    cat = next(name for name, words in categories if any(w in desc.lower() for w in words))
    # Submap binds go first within their category
    if b["submap"]:
        groups[cat].insert(sum(1 for c, _ in groups[cat] if "," in c), (combo, desc))
    else:
        groups[cat].append((combo, desc))
# Keys inside the clipboard menu (Super + Ctrl + V); rofi keys, not Hyprland binds
groups["Clipboard"] = [("Enter", "Copy the selected entry"), ("Alt + P", "Preview image full size"),
                       ("Alt + Delete", "Delete the selected entry"), ("Alt + Shift + Delete", "Clear all history")]
w = max(len(c) for rows in groups.values() for c, _ in rows)
first = True
for name in order:
    rows = groups[name]
    if not rows:
        continue
    if not first:
        print(" \0nonselectable\x1ftrue")
    first = False
    print(f"<b>{name}</b>\0nonselectable\x1ftrue")
    for c, d in rows:
        # meta: invisible search terms, so typing a category name lists all its binds
        print(html.escape(f"  {c:<{w}}     {d}") + f"\0meta\x1f{name}")
' > "$rows"

# Fit the window to the longest row (chars of the monospace font + theme padding)
chars=$(tr '\000' '\n' < "$rows" | grep -v -e '^<b>' -e '^nonselectable' | awk '{ if (length > m) m = length } END { print m }')

# Category headers are marked "active" so they get the orange highlight
headers=$(grep -an '^<b>' "$rows" | cut -d: -f1 | awk '{ printf "%s%d", (NR > 1 ? "," : ""), $1 - 1 }')

# Read-only list: clicks do nothing (no -me-accept-entry), only the wheel scrolls
rofi -dmenu -i -markup-rows -p " Keybinds" -no-custom -a "$headers" \
    -me-accept-entry "" -me-accept-custom "" \
    -theme "$HOME/.config/rofi/launchers/type-1/style-1.rasi" \
    -theme-str "window { width: calc(${chars}ch + 160px); } listview { columns: 1; lines: 15; }" \
    -theme-str 'element normal.active, element alternate.active, element selected.active { background-color: var(selected); text-color: var(background); }' \
    -theme-str 'prompt { font: "JetBrainsMono Nerd Font Bold 10"; }' \
    -theme-str 'element, element-text { cursor: default; }' \
    -theme-str 'element selected.normal { background-color: #292E42; text-color: var(foreground); }' < "$rows" >/dev/null
