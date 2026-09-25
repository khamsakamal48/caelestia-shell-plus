# caelestia-shell-plus

[caelestia-shell](https://github.com/caelestia-dots/shell) with a few additions
inspired by [Ryoku](https://github.com/ryoku-dev/ryoku):

- **Clipboard history panel.** Press **Super+V** and it slides out from the bar
  on the left, in the same style as the notification sidebar. It replaces the
  dots' fuzzel picker.
  - Type to search, move with **↑/↓**, and press **Enter** (or click) to copy.
  - **Delete** removes the selected entry; the sweep button clears everything.
  - Copied images show as thumbnails.
  - The ☆ button stars an entry. Starred entries stay at the top, and wiping
    the history doesn't remove them.
  - Search is fuzzy: "gtcm" finds "git commit".
  - A copy stays pasteable after you close the app you copied it from
    (`wl-clip-persist`).
  - It also opens with `caelestia shell drawers toggle clipboard`.
- **More quick toggles** in the bottom-right utilities panel (Super+N):
  - **Night light**: a warm screen via hyprsunset
  - **Clipboard**, **Search**, **Screenshot** and **Colour picker** buttons

  You can switch each one on or off in Nexus → Utilities.
- **Bibata Modern Ice cursor** (from `bibata-cursor-theme-bin` in the AUR),
  set in the installer's block in `~/.config/caelestia/hypr-user.lua`.
- **A crowded tray scrolls.** Past 8 icons, the tray stops growing and you
  scroll through its icons with the mouse wheel, so it can't push the clock and
  status icons off the bar. Over the tray, the wheel scrolls the icons instead
  of changing volume or brightness. Change the limit in Nexus → Taskbar → Tray
  → "Icons before scrolling" (0 turns it off).
- **Choose what the bar logo opens.** Turn on Nexus → Taskbar → "Logo opens
  quick settings" to open the utilities panel instead of the launcher.
- **Sleep and wake, as Ryoku does it.** The shell holds suspend until the lock
  screen is actually showing, so the machine never sleeps or wakes on an
  unlocked desktop. The installer lets logind wait up to 15s for this (the
  default is 5s). For 15s after waking, the shell keeps turning the displays
  back on, so closing the lid with idle timeouts off no longer wakes to a
  black screen.
- **A stuck fingerprint reader no longer locks you out of it.** After a
  suspend, fprintd sometimes rejects every scan instantly. The lock screen used
  to burn through all your fingerprint tries in a second and turn fingerprint
  off until the next lock. Now those instant failures don't count: after three
  it says "Fingerprint unavailable. Please use password." and quietly retries
  the reader every 2s, 4s, 8s... (up to a minute) until it answers.
- **Num Lock is on from login**, so the number pad types digits at the boot
  lock screen (the dots turn it off). Toggle it with the Num Lock key as usual.
- **Brightness on hybrid laptops.** On Intel + NVIDIA laptops, the slider and
  brightness keys now control the real panel instead of a phantom device
  (`caelestia-backlight` picks the one wired to the connected built-in screen).
- **The keyboard layout no longer sticks on "ERROR"** when Hyprland briefly
  reports it, for example while a virtual keyboard is changing.
- **Localised Pictures folder.** Screenshots go to your real Pictures folder
  (`~/Bilder`, `~/Images`...) instead of a new English `~/Pictures`.
- **Click the bar clock** to open the dashboard on its calendar (scroll to
  change month); click again to close.
- **Caps Lock and Num Lock are separate status icons**, so you can hide either
  one in Nexus → Taskbar → Status icons. If your config still lists the old
  combined "Lock keys (both)" entry, remove it there and add the ones you want.
- **Steadier external displays**, the way Ryoku handles them. When a display
  is plugged in or removed, `caelestia-monitor` lines the displays up
  left to right with no gaps. Until the new link has trained, it also keeps
  re-applying each display's best mode, so a display no longer stays stuck on
  a fallback mode and flickering until you reload. On Intel/AMD, DRM format
  modifiers are turned off (`AQ_NO_MODIFIERS=1`, from the next login), and
  Hyprland's own "scale changed" popup is hidden. Displays you set up in
  HyprMod or `hypr-user.lua` are left alone.
- **[HyprMod](https://github.com/BlueManCZ/hyprmod)** is installed from the AUR.
  Use it to switch Hyprland tiling layouts (Dwindle / Master / Scrolling /
  Monocle) under **Layout**; changes apply live.
- **Caelestia's lock screen at boot.** The installer sets up greetd to log you
  in once per boot, and the shell starts already locked, so you sign in on the
  same lock screen as Super+L. After you log out, greetd shows a plain text
  login. If another display manager (SDDM, GDM...) is enabled, the installer
  leaves it alone. Your keyring isn't unlocked at login, since no password is
  typed at that point.

## Install (Arch Linux)

1. Install the Caelestia dotfiles the normal way:

   ```sh
   paru -S caelestia-cli
   caelestia install
   ```

2. Replace the stock shell with this one:

   ```sh
   git clone https://github.com/khamsakamal48/caelestia-shell-plus
   cd caelestia-shell-plus
   ./install.sh
   ```

   The installer builds a `caelestia-shell-plus` package. Pacman asks once to
   replace `caelestia-shell`; answer **y**.

## Update

```sh
git pull && ./install.sh
```

`caelestia update` keeps working. It never brings the stock shell back,
because this package stands in for it.

## Uninstall

```sh
./install.sh --uninstall
```

This reinstalls the stock `caelestia-shell` from the AUR and gives Super+V back
to the fuzzel picker.

## What's changed from upstream

- **New files:**
  - `modules/clipboard/`: the clipboard panel
  - `services/Clipboard.qml` (cliphist) and `services/NightLight.qml` (hyprsunset)
  - `packaging/caelestia-backlight` (+ `test-caelestia-backlight.sh`)
  - `packaging/`, `install.sh`, this file
- **Small edits to upstream files:**
  - `components/ScreenState.qml`
  - `modules/drawers/{Panels,ContentWindow,Regions}.qml`
  - `modules/Shortcuts.qml`
  - `modules/utilities/cards/Toggles.qml`
  - `plugin/src/Caelestia/Config/utilitiesconfig.hpp`
  - `modules/nexus/pages/panels/UtilitiesPanel.qml`
  - `modules/bar/{Bar,components/Clock,components/StatusIcons,components/status/LockStatus}.qml`
  - `modules/nexus/pages/panels/taskbar/BarStatusIcons.qml`
  - `plugin/src/Caelestia/Config/barconfig.hpp`
  - `modules/IdleMonitors.qml`, `services/Brightness.qml`
  - `modules/lock/{Pam,center/StateMessage,center/PasswordInput}.qml`
  - `modules/bar/components/OsIcon.qml`, `modules/nexus/pages/panels/TaskbarPanel.qml`
  - `modules/bar/components/Tray.qml`, `modules/nexus/pages/panels/taskbar/BarTray.qml`
  - `plugin/src/Caelestia/Services/hyprdevices.cpp`

Upstream releases are merged into `main`.
