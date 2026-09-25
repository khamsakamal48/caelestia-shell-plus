#!/bin/bash
# fixture self-check for packaging/caelestia-monitor. fake hyprctl logs evals;
# fake sleep fails so the settle loop does one pass.
set -u
S=${1:-$(dirname "$0")/caelestia-monitor}; D=$(mktemp -d); mkdir -p "$D/bin" "$D/cfg/hypr" "$D/cfg/caelestia"
printf '#!/bin/bash\nif [[ $1 == monitors ]]; then cat "$FIX"; else echo "$2" >> "$LOG"; fi\n' > "$D/bin/hyprctl"
printf '#!/bin/sh\nexit 1\n' > "$D/bin/sleep"; cp "$D/bin/sleep" "$D/bin/systemd-detect-virt"; chmod +x "$D/bin/"*
mon() { jq -nc --arg n "$1" --argjson w "$2" --argjson h "$3" --argjson r "$4" --argjson x "$5" --argjson y "$6" --argjson pw "$7" --argjson modes "$8" \
  '{name:$n,width:$w,height:$h,refreshRate:$r,x:$x,y:$y,scale:1,transform:0,mirrorOf:"none",physicalWidth:$pw,availableModes:$modes}'; }
run() { printf '%s\n' "$@" | jq -s . > "$D/fix.json"; : > "$D/log"
  PATH="$D/bin:$PATH" FIX="$D/fix.json" LOG="$D/log" XDG_CONFIG_HOME="$D/cfg" XDG_RUNTIME_DIR="$D" bash "$S" >/dev/null 2>&1; cat "$D/log"; }
fail=0; check() { if grep -qF -- "$2" <<<"$3"; then echo "ok   $1"; else echo "FAIL $1: got [$3]"; fail=1; fi; }
none() { if [[ -z $2 ]]; then echo "ok   $1"; else echo "FAIL $1: got [$2]"; fail=1; fi; }
edp=$(mon eDP-1 1920 1080 60 0 0 310 '["1920x1080@60.00Hz"]')
hdmi=$(mon HDMI-A-1 1920 1080 100 1920 0 530 '["1920x1080@100.00Hz","1024x768@60.00Hz"]')
none "settled layout is left alone" "$(run "$edp" "$hdmi")"
check "stacked hotplug goes into a row" 'output = "HDMI-A-1", mode = "highrr", position = "1920x0", scale = 1,' "$(run "$edp" "$(mon HDMI-A-1 1920 1080 100 0 -1080 530 '["1920x1080@100.00Hz"]')")"
check "degraded link re-asserts highrr" '"HDMI-A-1", mode = "highrr"' "$(run "$edp" "$(mon HDMI-A-1 1024 768 60 1920 0 530 '["1920x1080@100.00Hz","1024x768@60.00Hz"]')")"
echo 'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x-1080" })' > "$D/cfg/hypr/hyprland-gui.lua"
none "HyprMod-pinned output and hand layout untouched" "$(run "$edp" "$(mon HDMI-A-1 1024 768 60 0 -1080 530 '["1920x1080@100.00Hz"]')")"
rm -rf "$D"; exit $fail
