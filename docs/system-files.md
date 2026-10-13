# System files

Files that live outside your home. `install.sh` lists them, asks once, backs up
any file it replaces to `~/.config/arch-melon/backup-<date>/system/`, and keeps a
copy of the arch-melon version in `~/.config/arch-melon/system/` (paths mirror
`/`: `etc/iwd/main.conf` there is `/etc/iwd/main.conf` on the system).

To reinstall one by hand:
`sudo install -m 0644 ~/.config/arch-melon/system/etc/iwd/main.conf /etc/iwd/main.conf`
(from a keybind or an app without a terminal, use `pkexec` instead of `sudo`).

| File | What it does |
|---|---|
| `etc/systemd/logind.conf.d/power-key.conf` | The power key opens the rofi power menu instead of shutting down |
| `etc/systemd/logind.conf.d/lid.conf` | Closing the lid suspends (on battery, charger and docked) |
| `etc/ly/config.ini` | Ly login screen look (Doom fire animation, palette colors) |
| `etc/iwd/main.conf` | iwd handles Wi-Fi with its own DHCP, DNS through systemd-resolved. Skipped when NetworkManager is enabled |
| `etc/pam.d/polkit-1` | Same as `system-auth`, except that closing a polkit password window (Cancel / Esc / Super+C) is not counted as a failed login by pam_faillock. Wrong passwords still are |
| `etc/security/faillock.conf` | After 3 wrong passwords the account is locked for 1 minute (Arch's default is 10) |
| `etc/tmpfiles.d/nopasswd.conf` | Deletes the passwordless-sudo drop-in at boot, so it never survives a reboot |
| `usr/local/bin/nopasswd-root` | Root half of `nopasswd` (Super+Ctrl+S). Installed twice, as `nopasswd-15min` and `nopasswd-nolimit`, so each polkit action shows its own text |
| `usr/share/polkit-1/actions/org.archmelon.nopasswd.policy` | The text of those two password windows ("Passwordless sudo for 15 min" / "no limit") |

## About the security-related ones
- **nopasswd** writes `/etc/sudoers.d/zz-nopasswd` (`NOPASSWD: ALL`, checked with
  `visudo`) only after you type your password in the polkit window, removes it
  after 15 minutes (or when toggled off), and a red shield shows in Waybar while
  it is on. To remove the feature: delete the two `/usr/local/bin/nopasswd-*`
  files and the `.policy`.
- **pam.d/polkit-1** only changes how an *aborted* authentication is counted.
  Delete the file to go back to Arch's default (`/usr/lib/pam.d/polkit-1`).
- **faillock.conf**: delete `unlock_time = 60` to go back to 10 minutes.
