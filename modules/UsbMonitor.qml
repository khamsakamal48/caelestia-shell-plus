import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// Plays a sound when a USB device is connected or removed, as Ryoku does.
Scope {
    id: root

    property real lastPlayed: 0

    Process {
        running: GlobalConfig.utilities.sounds.usbChanged
        // Whole devices only, not each interface. Line: "UDEV  [123.45] add  /devices/... (usb)"
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=usb/usb_device"]
        stdout: SplitParser {
            onRead: line => {
                const action = line.split(/\s+/)[2];
                if (action !== "add" && action !== "remove")
                    return;

                // A hub or composite device fires several events at once; one sound is enough
                const now = Date.now();
                if (now - root.lastPlayed < 700)
                    return;
                root.lastPlayed = now;

                Quickshell.execDetached(["pw-play", `/usr/share/sounds/freedesktop/stereo/device-${action === "add" ? "added" : "removed"}.oga`]);
            }
        }
    }
}
