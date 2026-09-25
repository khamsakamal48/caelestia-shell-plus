#!/usr/bin/env bash
# caelestia-shell-plus installer. Run on top of the Caelestia dots.
#
#   ./install.sh               build this checkout and install it (re-run after git pull)
#   ./install.sh --uninstall   go back to the stock caelestia-shell from the AUR
#
# The shell is built as a pacman package that replaces caelestia-shell. Super+V
# is rebound from the dots' fuzzel picker to the clipboard panel inside a marked
# block in the dots' update-safe ~/.config/caelestia/hypr-user.lua, and Print
# opens the full-screen shot in Satty for annotation. The cursor is set to
# Bibata Modern Ice in the same block, which also hooks caelestia-monitor to
# display hotplug, keeps copies alive (wl-clip-persist) and exports the
# localised Pictures folder. logind may wait 15s for the lock before sleep.
# Boot logs straight in through greetd and the shell starts on
# its own lock screen (skipped if another display manager is enabled).
set -euo pipefail

here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
user_lua=$cfg/caelestia/hypr-user.lua
begin='-- >>> caelestia-shell-plus >>>'
end='-- <<< caelestia-shell-plus <<<'

say() { echo "caelestia-shell-plus: $*" >&2; }
die() { say "$*"; exit 1; }

strip_block() {
    [[ -f $user_lua ]] && sed -i "\|^$begin\$|,\|^$end\$|d" "$user_lua"
    return 0
}

restart_shell() {
    caelestia shell -k >/dev/null 2>&1 || true
    sleep 1
    caelestia shell -d >/dev/null 2>&1 || say "start the shell with: caelestia shell -d"
    hyprctl reload >/dev/null 2>&1 || true
}

greetd_conf=/etc/greetd/config.toml
logind_conf=/etc/systemd/logind.conf.d/caelestia-shell-plus.conf

# The shell holds suspend until its lock is up (modules/IdleMonitors.qml), but
# logind's default 5s cap can run out while a display is reconfiguring (undock
# as the lid shuts) and the machine sleeps unlocked. Ryoku raises it the same way.
setup_logind() {
    printf '[Login]\nInhibitDelayMaxSec=15\n' | sudo install -Dm644 /dev/stdin "$logind_conf"
    sudo systemctl reload systemd-logind 2>/dev/null || true
}

# Autologin once per boot, flagging the session so the shell starts locked
# (modules/lock/Lock.qml). After a logout, greetd falls back to agreety.
setup_login() {
    local dm
    dm=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
    if [[ -n $dm && $dm != *greetd* ]]; then
        say "$(basename "$dm" .service) is your display manager, leaving login as is"
        return
    fi
    sudo pacman -S --needed --noconfirm greetd
    local hypr=start-hyprland
    command -v start-hyprland >/dev/null || hypr=Hyprland
    [[ -f $greetd_conf.orig ]] || sudo cp "$greetd_conf" "$greetd_conf.orig"
    sudo tee "$greetd_conf" >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "agreety --cmd $hypr"
user = "greeter"

[initial_session]
command = "sh -c 'touch \\"\$XDG_RUNTIME_DIR/caelestia-lock-on-start\\"; exec $hypr'"
user = "$USER"
EOF
    sudo systemctl enable greetd
}

undo_login() {
    [[ -f $greetd_conf.orig ]] && sudo mv "$greetd_conf.orig" "$greetd_conf"
    return 0
}

aur_helper() {
    local h
    for h in paru yay; do
        command -v "$h" >/dev/null && { echo "$h"; return; }
    done
    die "no AUR helper (paru or yay) found"
}

install_all() {
    [[ $EUID -ne 0 ]] || die "run as your user, not root (sudo is used for pacman)"
    [[ -f $cfg/hypr/hyprland.lua ]] || die "Caelestia dots not found: run 'paru -S caelestia-cli && caelestia install' first"
    command -v makepkg >/dev/null || die "makepkg not found: sudo pacman -S --needed base-devel"

    say "building the shell (this takes a few minutes)..."
    (cd "$here/packaging" && rm -f ./*.pkg.tar.* && makepkg -sf --noconfirm)
    local pkg
    pkg=$(ls -t "$here"/packaging/caelestia-shell-plus-*.pkg.tar.* | grep -v -- '-debug-' | head -1)
    say "installing $(basename "$pkg") (answer y to replace caelestia-shell)"
    sudo pacman -U "$pkg"
    "$(aur_helper)" -S --needed --noconfirm bibata-cursor-theme-bin hyprmod

    mkdir -p "$(dirname "$user_lua")"
    strip_block
    cat >> "$user_lua" <<EOF
$begin
hl.unbind("SUPER + V")
hl.bind("SUPER + V", hl.dsp.global("caelestia:clipboard"))
hl.unbind("Print")
hl.bind("Print", hl.dsp.exec_cmd("grim - | caelestia-annotate -"))
-- Random wallpaper (and scheme) from the wallpaper folder, as Ryoku's Super+Shift+W.
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("caelestia wallpaper -r"))
require("variables").cursorTheme = "Bibata-Modern-Ice"
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
-- Display hotplug, as Ryoku does it: no raw "scale changed" toast, and
-- caelestia-monitor re-asserts each new display's best mode once its link has
-- trained (else it can stay stuck on a fallback mode and flicker until reload).
hl.config({ misc = { disable_scale_notification = true } })
local function settle_monitors() hl.exec_cmd("caelestia-monitor") end
hl.on("hyprland.start", settle_monitors)
hl.on("monitor.added", settle_monitors)
hl.on("monitor.removed", settle_monitors)
-- Intel/AMD: skip DRM format modifiers, which flicker or black out outputs after
-- a hotplug or screen capture (Ryoku sets the same). Breaks nvidia, so not there.
local nv = io.open("/proc/driver/nvidia/version")
if nv then nv:close() else hl.env("AQ_NO_MODIFIERS", "1") end
-- The dots start with Num Lock off, so a PIN typed on the number pad at the
-- boot lock screen came through as arrow keys.
hl.config({ input = { numlock_by_default = true } })
-- Keep a copy alive after the app it came from closes (Ryoku runs the same).
hl.on("hyprland.start", function() hl.exec_cmd("pgrep -x wl-clip-persist || wl-clip-persist --clipboard regular") end)
-- The session never exports this, so a localised Pictures folder (~/Bilder...)
-- got a stray English ~/Pictures for screenshots beside it.
local xdg = io.popen("xdg-user-dir PICTURES 2>/dev/null")
local pictures = xdg and xdg:read("l")
if xdg then xdg:close() end
if pictures and pictures ~= "" then hl.env("XDG_PICTURES_DIR", pictures) end
$end
EOF

    hyprctl setcursor Bibata-Modern-Ice 24 >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice 2>/dev/null || true

    setup_logind
    setup_login
    restart_shell
    say "done: press Super+V for the clipboard history"
}

uninstall_all() {
    [[ $EUID -ne 0 ]] || die "run as your user, not root"
    "$(aur_helper)" -S caelestia-shell
    strip_block
    undo_login
    sudo rm -f "$logind_conf"
    restart_shell
    say "back to the stock caelestia-shell"
}

case "${1:-}" in
    "") install_all ;;
    --uninstall) uninstall_all ;;
    *) die "usage: $0 [--uninstall]" ;;
esac
