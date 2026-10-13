#!/usr/bin/env bash
# arch-melon installer, for a working Arch Linux install. Run it as your user (not root)
# from the cloned repo:  ./install.sh
#
# What it does, asking before the big steps:
#   1. Installs the packages in packages/ (and yay, if missing, for the AUR ones)
#   2. Backs up every file of yours it is about to replace (~/.config/arch-melon/backup-<date>)
#   3. Copies home/ into your home and fills in machine-specific values
#   4. Installs the system files in system/ (each one listed first; old ones backed up)
#   5. Enables the services
# Running it again updates the files and makes a new backup.

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA="$HOME/.config/arch-melon"
BACKUP="$DATA/backup-$(date +%Y%m%d-%H%M%S)"

say()  { printf '\n\033[1;38;2;255;158;100m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[38;2;224;175;104m    ! %s\033[0m\n' "$*"; }
ask()  { local a; read -rp "    $1 [Y/n] " a; [[ -z $a || $a =~ ^[Yy] ]]; }
pkgs() { grep -v -e '^#' -e '^$' "$REPO/packages/$1"; }

# --- Checks ---------------------------------------------------------------------------
[ -f /etc/arch-release ] || { echo "arch-melon is for Arch Linux."; exit 1; }
[ "$(id -u)" -ne 0 ]     || { echo "Run it as your user, not as root (it uses sudo when needed)."; exit 1; }
command -v sudo >/dev/null || { echo "sudo is needed: pacman -S sudo, and add yourself to wheel."; exit 1; }

cat <<EOF

  arch-melon: a Hyprland setup in Tokyo Night with one orange accent.

  Repo:    $REPO
  Backups: $BACKUP
EOF
ask "Continue?" || exit 0

# --- 1. Packages ----------------------------------------------------------------------
say "Packages"
sudo pacman -S --needed $(pkgs core-repo.txt)

if ! command -v yay >/dev/null; then
    info "Installing yay (AUR helper)"
    sudo pacman -S --needed git base-devel
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi
yay -S --needed $(pkgs core-aur.txt)

info "Extras: $(pkgs extras-repo.txt | tr '\n' ' ')$(pkgs extras-aur.txt | tr '\n' ' ')"
if ask "Install the extras (Betterbird mail, Docker + lazydocker)?"; then
    sudo pacman -S --needed $(pkgs extras-repo.txt)
    yay -S --needed $(pkgs extras-aur.txt)
fi

# --- 2 + 3. Your files ----------------------------------------------------------------
say "Files in your home"
mkdir -p "$BACKUP/home"
backed=0
while IFS= read -r -d '' src; do
    rel=${src#"$REPO/home/"}
    dest="$HOME/$rel"
    if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
        mkdir -p "$BACKUP/home/$(dirname "$rel")"
        cp -a "$dest" "$BACKUP/home/$rel"
        backed=$((backed + 1))
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
done < <(find "$REPO/home" -type f -print0)
info "Copied home/ into $HOME ($backed existing files backed up)"
chmod +x "$HOME"/.local/bin/* "$HOME"/.config/rofi/scripts/*.sh "$HOME"/.config/hypr/scripts/*.sh

# Machine-specific values
sed -i "s|/home/USER/|$HOME/|" "$HOME/.config/waybar/config.jsonc"
if [ ! -f "$HOME/.face" ]; then
    cp "$REPO/assets/defaults/face.png" "$HOME/.face"
    info "Profile picture: default one in ~/.face (replace it with yours, then run ./install.sh again)"
fi
# Waybar can't round images with CSS: keep a round copy of ~/.face
magick "$HOME/.face" -resize 128x128^ -gravity center -extent 128x128 \
    \( -size 128x128 xc:black -fill white -draw "circle 64,64 64,0" \) \
    -alpha off -compose CopyOpacity -composite "$HOME/.config/waybar/avatar.png"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings"
if [ -z "$(ls -A "$HOME/Pictures/Wallpapers")" ]; then
    cp "$REPO/assets/defaults/wallpaper.jpg" "$HOME/Pictures/Wallpapers/arch-melon.jpg"
    info "Wallpaper: put your own images in ~/Pictures/Wallpapers (one is picked at random)"
fi
fc-cache -f >/dev/null

# Docs and system file copies, where the scripts and the agent guide expect them
mkdir -p "$DATA"
rm -rf "$DATA/system"
cp -a "$REPO/system" "$DATA/system"
cp -a "$REPO/docs/." "$DATA/"
echo "$REPO" > "$DATA/source"

# --- 4. System files ------------------------------------------------------------------
say "System files"
cat <<'EOF'
    /etc/systemd/logind.conf.d/power-key.conf  power key opens the power menu
    /etc/systemd/logind.conf.d/lid.conf        closing the lid suspends
    /etc/ly/config.ini                         Ly login screen theme
    /etc/iwd/main.conf                         Wi-Fi with iwd (only if NetworkManager is off)
    /etc/pam.d/polkit-1                        cancelling a password window is not a failed login
    /etc/security/faillock.conf                after 3 wrong passwords, locked for 1 minute
    /etc/tmpfiles.d/nopasswd.conf              passwordless sudo never survives a reboot
    /usr/local/bin/nopasswd-15min, -nolimit    root half of Super+Ctrl+S (passwordless sudo)
    /usr/share/polkit-1/actions/org.archmelon.nopasswd.policy  its password window text
EOF
if ask "Install them? (existing ones are backed up)"; then
    nm=false
    systemctl is-enabled -q NetworkManager 2>/dev/null && nm=true
    sudo -v
    while IFS= read -r -d '' src; do
        rel=${src#"$REPO/system/"}
        case $rel in
            usr/local/bin/nopasswd-root) continue ;;      # installed twice below
            etc/iwd/*) $nm && { warn "NetworkManager is in use: skipping $rel"; continue; } ;;
        esac
        if sudo test -e "/$rel"; then
            mkdir -p "$BACKUP/system/$(dirname "$rel")"
            sudo cp -a "/$rel" "$BACKUP/system/$rel"
        fi
        sudo install -D -m 0644 "$src" "/$rel"
    done < <(find "$REPO/system" -type f -print0)
    for name in nopasswd-15min nopasswd-nolimit; do
        sudo install -D -m 0755 "$REPO/system/usr/local/bin/nopasswd-root" "/usr/local/bin/$name"
    done
    info "Installed (backups of the old ones in $BACKUP/system)"
fi

# --- 5. Services and theme ------------------------------------------------------------
say "Services and theme"
sudo systemctl enable --now bluetooth
if systemctl is-enabled -q NetworkManager 2>/dev/null; then
    warn "NetworkManager is in use: kept it. The network pill opens impala, which needs iwd;"
    warn "change its on-click in ~/.config/waybar/config.jsonc to 'kitty --class popup -e nmtui'."
elif ask "Use iwd + systemd-resolved for Wi-Fi (what the network pill expects)?"; then
    sudo systemctl enable --now iwd systemd-resolved
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi
if systemctl is-enabled -q display-manager 2>/dev/null; then
    warn "A login manager is already enabled: kept it (Ly is installed if you want to switch)."
elif ask "Enable Ly as the login screen?"; then
    sudo systemctl enable ly@tty2
fi
systemctl --user daemon-reload
systemctl --user enable --now update-count.timer
systemctl --user enable hyprpolkitagent

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Amber'
gsettings set org.gnome.desktop.interface cursor-size 24
sudo papirus-folders -C paleorange --theme Papirus-Dark >/dev/null || true

# --- Done -----------------------------------------------------------------------------
say "Done"
cat <<EOF
    Log out and pick Hyprland at the login screen. Super+K lists every keybind.

    Adapt to your machine (see $DATA/SYSTEM-CONFIG.txt):
      - Monitors: add yours at the top of ~/.config/hypr/hyprland.lua (hyprctl monitors)
      - Browser and mail app: "browser" and "mailClient" in the same file
      - Profile picture: ~/.face, then run ./install.sh again for the round copy

    Your previous files are in $BACKUP
EOF
