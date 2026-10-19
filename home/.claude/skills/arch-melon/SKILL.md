---
name: arch-melon
description: Guide for working on the arch-melon Hyprland setup (Arch Linux, Tokyo Night with one orange accent). Use whenever a task touches Hyprland binds, rules or monitors, Waybar modules, rofi menus, mako notifications, kitty, starship, bash/readline keys, hyprlock/hypridle, the polkit password window, the helper scripts in ~/.local/bin, system files kept in ~/.config/arch-melon/system, install.sh, or installing and adapting arch-melon on a new machine.
---

# arch-melon

arch-melon is a Hyprland setup for Arch Linux. Its repo (cloned anywhere) holds
`home/` (copied into `$HOME`), `system/` (files outside `$HOME`), `packages/` and
`install.sh`; the live files are the ones in `$HOME` and `/etc`. This guide is for
an agent changing the setup, fixing it, or adapting it to a new machine.

Stack: Hyprland (Lua config) · Waybar · rofi · kitty · starship · mako · hyprlock ·
hypridle · ly · hyprpolkitagent · pipewire.

## 1. Learn this machine first
Never assume monitor names, batteries or paths. Check:
```
hyprctl monitors                      # monitor names, resolution, scale, position
ls /sys/class/backlight               # backlight devices (intel_backlight, amdgpu_bl0, ...)
ls /sys/class/power_supply            # battery (BAT0/BAT1) and adapter (AC/ADP0/ADP1); none on a desktop
cat /sys/class/power_supply/*/scope   # "Device" = mouse/headset battery, not the laptop's (install.sh pins the other one in Waybar)
hyprctl devices                       # keyboards, touchpads, tablets
hyprctl version; pacman -Q hyprland waybar hyprpolkitagent
lspci -k | grep -A3 -E "VGA|3D"       # GPU (matters for screen recording)
```
Find the repo it was installed from: `cat ~/.config/arch-melon/source`. Check
whether the user keeps their own config in git (a fork of that repo, or a bare
repo like `~/.dotfiles`) and follow their workflow; if unsure, ask.

## 2. Where things live
| What | File |
|---|---|
| Full spec of every setting (read the section before changing it) | `~/.config/arch-melon/SYSTEM-CONFIG.txt` |
| System files (outside `$HOME`) and how to restore them | `~/.config/arch-melon/system-files.md` |
| README: style, Waybar table, keybinds, scripts, install | `README.md` in the repo |
| Hyprland: monitors, input, binds, rules, autostart | `~/.config/hypr/hyprland.lua` |
| Lock screen / idle | `~/.config/hypr/hyprlock.conf`, `hypridle.conf` |
| Theme of hyprtoolkit apps (polkit window) | `~/.config/hypr/hyprtoolkit.conf` |
| Bar | `~/.config/waybar/config.jsonc`, `style.css` |
| Menus (Super+K lists every bind) | `~/.config/rofi/scripts/*.sh` |
| Notifications | `~/.config/mako/config` |
| Terminal, prompt, shell | `~/.config/kitty/kitty.conf`, `~/.config/starship.toml`, `~/.bashrc`, `~/.inputrc` |
| Helper scripts | `~/.local/bin/` |
| Copies of system files (paths mirror `/`) | `~/.config/arch-melon/system/etc/...`, `usr/...` |
| Package lists | `packages/core-repo.txt`, `core-aur.txt` in the repo |

Helper scripts (each prints usage in its header comment):
| Script | Does | Needs |
|---|---|---|
| `osd` | Volume, mic and brightness keys with a mako popup | wpctl, brightnessctl |
| `screenrec` | Screen recording toggle (region / monitor) | gpu-screen-recorder, slurp |
| `ocr` | Copies the text in a selected area | grim, slurp, tesseract |
| `nightlight` | Warmer colors on/off | hyprsunset |
| `keepawake` | Keep Awake: no screen lock or suspend while on | systemd-inhibit |
| `nopasswd` | Passwordless sudo for 15 min, or on/off (Super+Ctrl+S / Super+Ctrl+Alt+S) | pkexec, polkit policy in `~/.config/arch-melon/system` |
| `update-count` | Pending updates for the bar and prompt (hourly user timer) | pacman-contrib, yay |
| `system-update` | Update window (Super+Ctrl+U, updates pill): lists updates, runs yay, refreshes the count | pacman-contrib, yay |
| `waybar-ccusage`, `claude-costs` | Claude plan usage pill and cost table (optional) | ccusage, a Claude Code login |

## 3. Every change
1. **Apply it:**
   - Hyprland: `hyprctl reload`, then `hyprctl configerrors` (must be empty).
   - Waybar: `pkill -SIGUSR2 -x waybar` (reload) or Super+Ctrl+R (restart).
   - kitty: `pkill -USR1 -x kitty`. mako: `makoctl reload`.
   - polkit agent: `systemctl --user restart hyprpolkitagent`.
   - Bash reads `~/.inputrc` only at start (`bind -f ~/.inputrc` in an open shell).
2. **Update the doc that describes it:** `~/.config/arch-melon/SYSTEM-CONFIG.txt`
   (and `system-files.md` for system files), so the next change starts from the
   truth. If the user maintains a fork of the repo, mirror the change into its
   `home/`, `system/` and `docs/` too. Docs are in English.
3. **Version control:** if the user keeps their config in git, commit there with a
   message that says what and why. Never force-push. Follow the user's own rules
   for commits and pushes when they have them.

**Re-running `install.sh`** overwrites the live files with the repo's (after a
backup in `~/.config/arch-melon/backup-<date>/`), so changes made only in `$HOME`
are replaced. Warn the user before running it, or merge from the backup after.

**System files** (anything outside `$HOME`): edit the copy in
`~/.config/arch-melon/system/`, then the user installs it, e.g.
`pkexec install -m 0644 ~/.config/arch-melon/system/etc/foo.conf /etc/foo.conf`.
The file in `/etc` or `/usr` is what the system reads.

## 4. Style
- One palette: Tokyo Night base, **orange `#ff9e64` is the only accent** (focused,
  active, selected). Background `#1a1b26`, surface `#1f2335`, text `#c0caf5`, dim
  `#565f89`, blue `#7aa2f7`. Green `#9ece6a` = good, yellow `#e0af68` = attention,
  red `#f7768e` = critical. Colors always mean the same thing.
- Pills floating over the wallpaper; JetBrainsMono Nerd Font everywhere (icons too);
  things show only when they matter (hidden at zero or when off).
- **Use each tool's own options.** Avoid glue that pipes one tool's data into
  another just to reformat it. If a tool can't do something natively, say so and
  offer the closest native option.
- Match the surrounding code: a short comment above each block saying what it does.

## 5. Waybar custom modules
A toggle script refreshes its pill with `pkill -RTMIN+<n> -x waybar`; its `status`
argument prints the module JSON (`{"text":""}` hides the pill).
| Signal | Module | Script |
|---|---|---|
| 8 | custom/dnd | `makoctl mode -t do-not-disturb` |
| 9 | custom/updates | `update-count` |
| 10 | custom/keepawake | `keepawake` |
| 11 | custom/recording | `screenrec` |
| 12 | custom/sudo | `nopasswd` |

Next free signal: **13**. Check with `grep -rn RTMIN ~/.local/bin ~/.config`.

## 6. Adapting to a new machine
Hardware-specific values, where they are and how to find the right one:
| Setting | Where | Find it with |
|---|---|---|
| Monitors (name, mode, position, scale) and which workspace opens where | `hyprland.lua`: `hl.monitor` blocks and `hl.workspace_rule` | `hyprctl monitors` |
| Backlight device | `waybar/config.jsonc` → `backlight.device` (`osd` loops over all devices) | `ls /sys/class/backlight` |
| Battery and adapter | `waybar/config.jsonc` → `battery.bat` / `adapter`; `hyprlock.conf` (battery line); `rofi/scripts/battery.sh` (`bat=`) | `ls /sys/class/power_supply` |
| No battery (desktop) | Remove the battery module and the hyprlock battery label | |
| Keyboard layout | `hyprland.lua` → `input.kb_layout` / `kb_variant` / `kb_options` | `localectl list-x11-keymap-variants us` |
| Keyboard backlight keys | `hyprland.lua` (`*kbd_backlight`) | `brightnessctl -l` |
| Profile picture | `~/.face` (hyprlock) and a round copy whose **absolute** path is in `waybar/config.jsonc` → `user.avatar` | |
| Absolute home paths | `grep -rn "/home/" ~/.config` and fix to the new user | |
| Screen recording encoder | `screenrec` uses the GPU through VA-API; Intel needs `intel-media-driver`, AMD `libva-mesa-driver`; NVIDIA works differently | `vainfo` |
| OCR languages | `ocr` (`tesseract -l ...`) and the `tesseract-data-*` packages | |

`install.sh` fills in what it can (avatar path, default picture and wallpaper,
NetworkManager vs iwd, login manager); the rest is the table above.
Files not covered here: read their section in `SYSTEM-CONFIG.txt` before touching.

## 7. Troubleshooting
Start from evidence: `journalctl -b` (system), `journalctl --user -b` (user
services), Hyprland's log in `$XDG_RUNTIME_DIR/hypr/*/hyprland.log`. For hypr*
tools, when behavior is unclear, `git clone` the project into a scratch dir and
`grep` the source instead of guessing.

**A bind does nothing**
- `hyprctl binds -j | jq '.[] | select(.description|test("..."))'`: is it loaded?
- Commands from binds run in Hyprland's environment, not your shell's. When the
  session is started by a display manager, `PATH` may lack `~/.local/bin`:
  compare `tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep PATH`.
  Use full paths (`$HOME/.local/bin/x`) in binds.
- stdin of bind commands can be the login console (`TERM=linux`): `[ -t 0 ]` is
  true but nobody can type there, so `sudo` waits forever. Use `pkexec`.

**Something needs root from a bind, a script or an agent's shell**
Use `pkexec` (password in the polkit window), not `sudo` (needs a terminal to
type in). `pkexec` needs a running polkit agent:
`systemctl --user status hyprpolkitagent`. Its unit is wanted by
`graphical-session.target`, which some sessions never reach; then start it from
the autostart block in `hyprland.lua`.

**"N minutes left to unlock" / sudo refuses a correct password**
That is pam_faillock: too many failed attempts. `faillock --user $USER` lists them;
they expire after `unlock_time` (`/etc/security/faillock.conf`). **Every aborted
authentication counts**: a killed `sudo`, a closed or cancelled polkit window.
Never open or kill password prompts to test something: prepare the change, let
the user trigger it, ask for a screenshot.

**Cancelling the polkit window counts as a failed login** (polkit 127 with its
socket-activated helper): the agent closes the socket, PAM gets no answer and
returns `PAM_AUTHTOK_ERR`, and `system-auth` sends that to `pam_faillock authfail`.
Fix: `/etc/pam.d/polkit-1` with the auth lines of `system-auth` but
`[success=1 authtok_err=die default=bad]` on `pam_unix.so` (copy in
`~/.config/arch-melon/system/etc/pam.d/`). Wrong passwords still count.

**Polkit window text** (hyprpolkitagent 0.2 + hyprtoolkit 0.6; recheck on newer versions)
- The action's `<message>` shows only when the request has no command line;
  plain `pkexec cmd` shows "Allow this action?" and the command. For a custom
  message, `pkexec` a program that has its own polkit action (see `nopasswd` and
  its `.policy` in `~/.config/arch-melon/system/usr/share/polkit-1/actions/`).
- `<message>` is Pango markup, max 120 bytes **counting the markup**, **one line
  only** (a second line is dropped), cut with "..." past ~340 px.
- polkit keeps only the **last chunk** of a message's text, and the XML parser
  splits at entities (`&lt;`) and newlines: write it as one `<![CDATA[...]]>` with
  neither.
- Window width is 460-600 px. A bigger `window_width` was ignored and a wider
  `password_field_width` made the password box disappear: keep the defaults.
- Title and buttons are fixed text in the agent; font and colors come from
  `hyprtoolkit.conf` (sizes in points: h1 19, h2 15, h3 13, body 11, small 10).
  Prefer `size='15pt'` in the message markup over changing a shared size.
- A clipped icon glyph (e.g. the password eye) means a fallback Mono Nerd Font:
  `font_family = Noto Sans, JetBrainsMono Nerd Font Propo`.
- A changed `.policy` does nothing until it is installed to
  `/usr/share/polkit-1/actions/`; check with `pkaction -v -a <action.id>`.

**Keys in kitty and bash**
kitty never sends Super to bash: translate it in `kitty.conf` with
`map super+<key> send_text normal <bytes>` ("normal" leaves full-screen apps
like vim or Claude Code alone). Ctrl combos go in `~/.inputrc` (start it with
`$include /etc/inputrc`). Find what kitty sends with `kitten show-key`.

**An app opens only on the second try, or seems not to open**
Hyprland has no minimize and the bar shows no tray, so an app set to "start
minimized" or "minimize/close to tray" runs invisibly; the second launch asks
the running copy for a window. Turn that option off in the app.

**Notifications don't show**
`makoctl mode`: `do-not-disturb` hides them (Super+Ctrl+D). `makoctl restore`
brings the last one back.

**Waybar pill missing**
Run the module's `exec` command by hand and check its JSON; run `waybar` in a
terminal to see its errors; `hyprctl configerrors` won't show Waybar problems.

## 8. Ground rules
- Don't trigger, cancel or kill password prompts yourself (see faillock above).
- Don't force-push, don't rewrite the repo's history, don't delete tracked files
  without asking.
- Keep personal data out of shared files: avatars, account names, network names,
  emails, tokens.
- When a value depends on the hardware, detect it (section 1) instead of copying
  it from this guide or from the repo.
