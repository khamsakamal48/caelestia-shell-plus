pragma Singleton

import Quickshell
import Quickshell.Io

// Hyprland tiling layout switcher (after Ryoku's LayoutControl). A choice
// applies live through the Lua config's eval and is saved to
// ~/.config/caelestia/layout.lua, which hypr-user.lua loads on every reload.
Singleton {
    id: root

    readonly property list<string> layouts: ["dwindle", "master", "scrolling", "monocle"]
    property string current

    function choose(layout: string): void {
        if (!layouts.includes(layout))
            return;
        const lua = `hl.config({ general = { layout = "${layout}" } })`;
        current = layout;
        Quickshell.execDetached(["hyprctl", "eval", lua]);
        saved.setText(lua + "\n");
    }

    function refresh(): void {
        probe.running = true;
    }

    FileView {
        id: saved

        path: `${Quickshell.env("HOME")}/.config/caelestia/layout.lua`
        printErrors: false
    }

    Process {
        id: probe

        running: true
        command: ["hyprctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ws = JSON.parse(text);
                    root.current = ws.tiledLayout ?? ws.layout ?? root.current;
                } catch (e) {}
            }
        }
    }
}
