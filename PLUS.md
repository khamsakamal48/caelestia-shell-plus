# caelestia-shell-plus

[caelestia-shell](https://github.com/caelestia-dots/shell) with a few additions
inspired by [Ryoku](https://github.com/ryoku-dev/ryoku):

- **Clipboard history panel.** Press **Super+V** and it slides out from the bar
  on the left, in the same style as the notification sidebar. It replaces the
  dots' fuzzel picker.
  - Type to search, move with **↑/↓**, and press **Enter** (or click) to copy.
  - **Delete** removes the selected entry; the sweep button clears everything.
  - Copied images show as thumbnails.
  - It also opens with `caelestia shell drawers toggle clipboard`.
- **More quick toggles** in the bottom-right utilities panel (Super+N):
  - **Night light**: a warm screen via hyprsunset
  - **Clipboard**, **Search**, **Screenshot** and **Colour picker** buttons

  You can switch each one on or off in Nexus → Utilities.
- **Bibata Modern Ice cursor** (from `bibata-cursor-theme-bin` in the AUR),
  set in the installer's block in `~/.config/caelestia/hypr-user.lua`.
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

Upstream releases are merged into `main`.
