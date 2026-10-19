# Changelog

## 0.1.1

- `uninstall.sh`: deletes what arch-melon added and restores your original files from the
  oldest backup (system files only after asking). `install.sh` now records the files it
  creates in `~/.config/arch-melon/created` for this.
- Update window (`Super + Ctrl + U`, updates pill): lists the pending updates (repo and
  AUR, old → new) before yay asks for the password; "up to date" without asking at all.
- AI pill no longer disappears when the 5-hour window has not started yet.
- Every script is checked by ShellCheck on each push (GitHub Actions).

## 0.1.0

First public version.

- Hyprland (Lua config), Waybar, rofi, kitty, starship, mako, hyprlock, hypridle and Ly in
  Tokyo Night with one orange accent.
- `install.sh` for an existing Arch install: packages (Chrome, Betterbird and ccusage included), backups of replaced files, system
  files after listing them, services. Detects NetworkManager and existing login managers.
- Helper scripts: volume/brightness OSD, screen recording, OCR, night light, Keep Awake,
  pending updates, passwordless sudo on demand, Claude plan usage (optional).
- Monitors and backlight found automatically; `install.sh` pins the laptop battery in Waybar
  (device batteries like wireless mice are left out) and offers to reboot at the end.
- Clipboard history kept in RAM: never written to disk, gone at shutdown or reboot.
- Wallpapers dealt like a shuffled deck: no repeats until every image has been shown.
- Quiet bar: the updates pill (center, next to the bell) hides at zero, the AI pill hides
  without a Claude Code login. Default profile picture and wallpaper.
- Claude Code skill (`home/.claude/skills/arch-melon`) as a guide for AI agents.
