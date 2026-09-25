pragma ComponentBehavior: Bound

import "lock"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(Hypr.usingLua && ["dpms off", "dpms on"].includes(action) ? `hl.dsp.dpms({ action = "${action === "dpms off" ? "disable" : "enable"}" })` : action);
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    // Hold suspend until the lock is on screen, else the machine sleeps (and
    // wakes) showing the desktop. logind waits up to InhibitDelayMaxSec.
    Process {
        id: sleepDelay

        property bool sleeping

        running: GlobalConfig.general.idle.lockBeforeSleep
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=caelestia-shell", "--why=Lock the screen before sleep", "sleep", "infinity"]
    }

    Connections {
        function onSecureChanged(): void {
            if (root.lock.lock.secure && sleepDelay.sleeping)
                sleepDelay.running = false;
        }

        target: root.lock.lock
    }

    // After a wake, keep turning the displays back on for 15s. A panel still
    // re-training can drop a single "on", and nothing else powers it back up
    // when the idle timeouts are off, so a lid close woke to a black screen.
    Timer {
        id: wakeGuard

        property int left

        interval: 1000
        repeat: true
        onTriggered: {
            root.handleIdleAction("dpms on");
            if (--left <= 0)
                stop();
        }
    }

    Connections {
        function onAboutToSleep(): void {
            if (GlobalConfig.general.idle.lockBeforeSleep) {
                sleepDelay.sleeping = true;
                root.lock.lock.locked = true;
                if (root.lock.lock.secure)
                    sleepDelay.running = false;
            }
        }

        function onResumed(): void {
            sleepDelay.sleeping = false;
            sleepDelay.running = GlobalConfig.general.idle.lockBeforeSleep;
            wakeGuard.left = 15;
            wakeGuard.restart();
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts.values

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
