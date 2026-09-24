pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Airplane mode: every rfkill radio soft-blocked. Read from rfkill, so a block
// set elsewhere (hardware key, nmcli) also shows as on.
Singleton {
    id: root

    property bool enabled

    function toggle(): void {
        enabled = !enabled;
        Quickshell.execDetached(["rfkill", enabled ? "block" : "unblock", "all"]);
    }

    // rfkill has no event hook we can cheaply bind to; poll while the shell runs.
    // ponytail: 5s poll, switch to `rfkill event` stream if latency matters
    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 5000
        onTriggered: state.running = true
    }

    Process {
        id: state

        command: ["sh", "-c", "s=$(rfkill -rn -o SOFT); [ -n \"$s\" ] && ! echo \"$s\" | grep -qx unblocked"]
        onExited: code => root.enabled = code === 0
    }
}
