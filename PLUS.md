# caelestia-shell-plus

[caelestia-shell](https://github.com/caelestia-dots/shell) with two additions
from [Ryoku](https://github.com/ryoku-dev/ryoku):

- **A control panel.** It slides out from the bar on the left. Open it with
  **Super+A**, by clicking the clock in the bar, or with
  `caelestia shell drawers toggle controls`. It has:
  - the clock, the date, the battery, and logout / lock / reboot / power off
    (reboot and power off only fire after a 0.7 s hold)
  - Connect tiles: Wi-Fi, Bluetooth, Airplane, Night light, Keep awake,
    Do not disturb, Gaming
  - volume, microphone and brightness sliders
  - a calendar
  - **Layout**: switch Hyprland tiling between Dwindle, Master, Scrolling and
    Monocle, live. The choice is remembered across `hyprctl reload`.
  - **Power**: power profile (Saver / Balanced / Performance)
- **More quick actions** in the bottom-right utilities panel: control panel,
  search, screenshot and colour picker, next to the existing toggles. You can
  switch each one on or off in Nexus → Utilities.

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

This reinstalls the stock `caelestia-shell` from the AUR and removes the
Super+A bind.

## What's changed from upstream

- **New files:**
  - `modules/controls/`: the panel
  - `services/NightLight.qml` (hyprsunset) and `services/Layouts.qml`
  - `packaging/`, `install.sh`, this file
- **Small edits to upstream files:**
  - `components/ScreenState.qml`
  - `modules/drawers/{Panels,ContentWindow,Regions}.qml`
  - `modules/Shortcuts.qml`
  - `modules/bar/components/Clock.qml`
  - `modules/utilities/cards/Toggles.qml`
  - `plugin/src/Caelestia/Config/utilitiesconfig.hpp`
  - `modules/nexus/pages/panels/UtilitiesPanel.qml`

Upstream releases are merged into `main`.
