# Changelog

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
