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
# Bibata Modern Ice in the same block.
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
require("variables").cursorTheme = "Bibata-Modern-Ice"
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
$end
EOF

    hyprctl setcursor Bibata-Modern-Ice 24 >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice 2>/dev/null || true

    restart_shell
    say "done: press Super+V for the clipboard history"
}

uninstall_all() {
    [[ $EUID -ne 0 ]] || die "run as your user, not root"
    "$(aur_helper)" -S caelestia-shell
    strip_block
    restart_shell
    say "back to the stock caelestia-shell"
}

case "${1:-}" in
    "") install_all ;;
    --uninstall) uninstall_all ;;
    *) die "usage: $0 [--uninstall]" ;;
esac
