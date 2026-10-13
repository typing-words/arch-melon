#!/usr/bin/env bash
# Rofi "apps" mode: lists only user-installed apps, showing name and icon.

# Packages explicitly installed before this date (base install) are hidden.
CUTOFF="2026-10-06 19:00"
# .desktop files never shown (tools, not apps)
EXCLUDE=(rofi.desktop rofi-theme-selector.desktop)

# On selection, rofi calls the script again with the .desktop path in ROFI_INFO
if [ "$ROFI_RETV" = 1 ]; then
    f="$ROFI_INFO"
    if grep -q '^Terminal=true' "$f"; then
        cmd=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ %[a-zA-Z]//g')
        setsid -f kitty -e sh -c "$cmd" >/dev/null 2>&1
    else
        setsid -f gtk-launch "$(basename "$f")" >/dev/null 2>&1
    fi
    exit 0
fi

# The launcher builds the list once and passes it in, so rofi doesn't build it again
if [ -n "$APPS_LIST" ] && [ -f "$APPS_LIST" ]; then
    cat "$APPS_LIST"
    exit 0
fi

cutoff_ts=$(date -d "$CUTOFF" +%s)
declare -A seen pkg_of
files=()
for f in ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop; do
    [ -f "$f" ] || continue
    id=$(basename "$f")
    [ -n "${seen[$id]}" ] && continue
    seen[$id]=1
    [[ " ${EXCLUDE[*]} " == *" $id "* ]] && continue
    files+=("$f")
done

# Read Name, Icon and NoDisplay/Hidden of every file in one awk pass (one grep per file was slow)
declare -A name_of icon_of
files_shown=()
while IFS=$'\t' read -r f hidden name icon; do
    [ "$hidden" = 1 ] && continue
    files_shown+=("$f")
    name_of[$f]=$name
    icon_of[$f]=$icon
done < <(awk -F= '
    FNR == 1 { if (NR > 1) print out(); file = FILENAME; hidden = 0; name = ""; icon = "" }
    tolower($0) ~ /^(nodisplay|hidden)=true/ { hidden = 1 }
    /^Name=/ && name == "" { name = substr($0, 6) }
    /^Icon=/ && icon == "" { icon = substr($0, 6) }
    function out() { return file "\t" hidden "\t" name "\t" icon }
    END { if (NR > 0) print out() }
' "${files[@]}")
files=("${files_shown[@]}")

# Owning package of each .desktop (files in ~/.local have no owner and count as user apps)
while read -r path _ _ _ pkg _; do
    pkg_of[$path]=$pkg
done < <(pacman -Qo "${files[@]}" 2>/dev/null | sed 's/ is owned by / x x x /')

# Explicit packages installed after the cutoff
declare -A user_pkg
# Dates are converted in a single date call (one fork per package was slow)
mapfile -t names < <(LC_ALL=C pacman -Qei 2>/dev/null | awk -F' : ' '/^Name/{print $2}')
mapfile -t stamps < <(LC_ALL=C pacman -Qei 2>/dev/null | awk -F' : ' '/^Install Date/{print $2}' | date -f - +%s)
for i in "${!names[@]}"; do
    [ "${stamps[$i]}" -gt "$cutoff_ts" ] && user_pkg[${names[$i]}]=1
done

printf '\0no-custom\x1ftrue\n'
for f in "${files[@]}"; do
    pkg=${pkg_of[$f]}
    [ -n "$pkg" ] && [ -z "${user_pkg[$pkg]}" ] && continue
    name=${name_of[$f]}
    icon=${icon_of[$f]}
    printf '%s\t%s\t%s\n' "$name" "$icon" "$f"
done | sort -f | while IFS=$'\t' read -r name icon f; do
    printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' "$name" "$icon" "$f"
done
