pragma Singleton

import Quickshell
import Quickshell.Io

// Night light: a warm hyprsunset while enabled. The running process is the
// state, so a hyprsunset started elsewhere also reads as on.
Singleton {
    id: root

    property bool enabled
    property int temperature: 4500

    function toggle(): void {
        set(!enabled);
    }

    function set(on: bool): void {
        enabled = on;
        if (on)
            Quickshell.execDetached(["sh", "-c", `pgrep -x hyprsunset >/dev/null || exec hyprsunset -t ${temperature}`]);
        else
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
    }

    Process {
        running: true
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.enabled = code === 0
    }
}
