#!/usr/bin/env bash
# arch-melon uninstaller. Run it as your user:  ./uninstall.sh
#
# Puts your machine back the way it was before the first ./install.sh:
#   1. Files arch-melon added (listed in ~/.config/arch-melon/created) are deleted
#   2. Files it replaced come back from the oldest backup (~/.config/arch-melon/backup-<date>)
#   3. The update counter timer is disabled and the GNOME look settings are reset
# Packages, services you enabled (bluetooth, iwd, Ly) and the backups themselves are left
# alone; the end of the run says how to remove them.

set -euo pipefail

DATA="$HOME/.config/arch-melon"
CREATED="$DATA/created"

say()  { printf '\n\033[1;38;2;255;158;100m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[38;2;224;175;104m    ! %s\033[0m\n' "$*"; }
ask()  { local a; read -rp "    $1 [y/N] " a; [[ $a =~ ^[Yy] ]]; }

[ "$(id -u)" -ne 0 ] || { echo "Run it as your user, not as root (it uses sudo when needed)."; exit 1; }
[ -d "$DATA" ] || { echo "No arch-melon install found ($DATA does not exist)."; exit 1; }

# Oldest first: the first backup holds your files from before arch-melon
mapfile -t backups < <(find "$DATA" -maxdepth 1 -type d -name 'backup-*' | sort)
mapfile -t added < <(grep -v '^$' "$CREATED" 2>/dev/null || true)

# The oldest backed-up copy of a file: "<home|system>" "<path relative to it>"
oldest() {
    local b
    for b in "${backups[@]}"; do
        [ -e "$b/$1/$2" ] && { echo "$b/$1/$2"; return 0; }
    done
    return 1
}
is_added() { [ -f "$CREATED" ] && grep -qxF -- "$1" "$CREATED"; }

# Every backed-up path, relative to its root, without duplicates
backed_up() {
    local b
    for b in "${backups[@]}"; do
        [ -d "$b/$1" ] && (cd "$b/$1" && find . -type f -printf '%P\n')
    done | sort -u
}

cat <<EOF

  This removes arch-melon and restores your previous files.

  Files added by arch-melon:  ${#added[@]}
  Backups found:              ${#backups[@]} (in $DATA)
EOF
[ -f "$CREATED" ] || warn "No list of added files (installed before uninstall.sh existed): only backups are restored."
warn "Changes you made to arch-melon's own files are lost. Copy anything you want to keep first."
ask "Continue?" || exit 0

# --- 1 + 2. Your files ----------------------------------------------------------------
say "Files in your home"
removed=0; restored=0
for f in "${added[@]}"; do
    [[ $f == "$HOME"/* ]] || continue
    rm -f -- "$f" && removed=$((removed + 1))
done
while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    is_added "$HOME/$rel" && continue
    src=$(oldest home "$rel") || continue
    mkdir -p "$(dirname "$HOME/$rel")"
    cp -a -- "$src" "$HOME/$rel" && restored=$((restored + 1))
done < <(backed_up home)
info "Removed $removed added files, restored $restored of yours"

# --- System files ----------------------------------------------------------------------
sys_added=()
for f in "${added[@]}"; do [[ $f == /etc/* || $f == /usr/* ]] && sys_added+=("$f"); done
mapfile -t sys_backed < <(backed_up system)
if [ ${#sys_added[@]} -gt 0 ] || [ ${#sys_backed[@]} -gt 0 ]; then
    say "System files"
    for f in "${sys_added[@]}"; do info "remove   $f"; done
    for rel in "${sys_backed[@]}"; do info "restore  /$rel"; done
    if ask "Change them? (needs sudo)"; then
        for f in "${sys_added[@]}"; do sudo rm -f -- "$f"; done
        for rel in "${sys_backed[@]}"; do
            src=$(oldest system "$rel") || continue
            sudo install -D -m "$(stat -c %a "$src")" "$src" "/$rel"
        done
        sudo rm -f /etc/sudoers.d/zz-nopasswd   # passwordless sudo, if it was on
        info "Done"
    fi
fi

# --- 3. Services and theme -------------------------------------------------------------
say "Services and theme"
systemctl --user disable --now update-count.timer 2>/dev/null || true
systemctl --user daemon-reload
for key in color-scheme gtk-theme icon-theme cursor-theme cursor-size; do
    gsettings reset org.gnome.desktop.interface "$key"
done
info "Update counter off, GTK look back to defaults"

# The list of added files has been used; keep the backups
rm -f "$CREATED"

say "Done"
cat <<EOF
    Log out (or reboot) to leave the arch-melon session.

    Left in place, remove them if you want:
      - Backups:   rm -r $DATA
      - Packages:  see packages/*.txt in the repo (sudo pacman -Rns <names>)
      - Services:  bluetooth, iwd, Ly (sudo systemctl disable <name>)
EOF
