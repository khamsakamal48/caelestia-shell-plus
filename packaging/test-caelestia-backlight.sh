#!/bin/bash
# fixture self-check for packaging/caelestia-backlight: a fake sysfs per case.
set -u
S=${1:-$(dirname "$0")/caelestia-backlight}; D=$(mktemp -d); fail=0
run() { CAELESTIA_BACKLIGHT_PATH="$D/bl" CAELESTIA_DRM_PATH="$D/drm" sh "$S"; }
check() { if [[ $2 == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: got [$3]"; fail=1; fi; }
# $1 backlight name, $2 its device (made under $D/dev)
bl() { mkdir -p "$D/bl/$1" "$D/dev/$2"; ln -s "$D/dev/$2" "$D/bl/$1/device"; }
card() { mkdir -p "$D/drm/$1" "$D/dev/$2"; ln -sfn "$D/dev/$2" "$D/drm/$1/device"; }
panel() { mkdir -p "$D/dev/$1"; echo "$2" > "$D/dev/$1/status"; ln -s "$D/dev/$1" "$D/drm/${1##*/}"; }

# Intel + NVIDIA hybrid, panel on Intel: skip acpi_video0 and nvidia_0
mkdir -p "$D/drm"; card card0 pci/nv; card card1 pci/intel; panel pci/intel/card1-eDP-1 connected
bl acpi_video0 acpi/video; bl nvidia_0 pci/nv; bl intel_backlight pci/intel/card1-eDP-1
check "hybrid picks the Intel panel" intel_backlight "$(run)"

# MUX set to discrete: the panel hangs off the NVIDIA card
rm -rf "$D"/*; mkdir -p "$D/drm"; card card0 pci/nv; card card1 pci/intel
panel pci/nv/card0-eDP-1 connected; panel pci/intel/card1-eDP-1 disconnected
bl intel_backlight pci/intel/card1-eDP-1; bl nvidia_0 pci/nv
check "MUX discrete picks nvidia_0" nvidia_0 "$(run)"

# no DRM mapping: name list
rm -rf "$D"/*; bl acpi_video0 acpi/video; bl intel_backlight x
check "no DRM tree falls back to intel_backlight" intel_backlight "$(run)"

rm -rf "$D"; exit $fail
