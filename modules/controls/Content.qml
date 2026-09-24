pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.dashboard.dash as Dash

// The control panel body: Ryoku's quick-settings home laid out with
// Caelestia's controls and palette. Clock and session, Connect tiles, sound
// and display sliders, calendar, tiling layout and power profile.
Flickable {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property var bt: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool btOn: bt?.enabled ?? false
    readonly property var monitor: Brightness.getMonitorForScreen(screen)
    readonly property var battery: UPower.displayDevice

    function exec(command: list<string>): void {
        if (!SessionManager.exec(command))
            Quickshell.execDetached(command);
    }

    function ipc(target: string, fn: string): void {
        Quickshell.execDetached(["qs", "-c", "caelestia", "ipc", "call", target, fn]);
    }

    contentHeight: column.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    Component.onCompleted: Layouts.refresh()

    ColumnLayout {
        id: column

        width: root.width
        spacing: Tokens.spacing.medium

        // --- clock + session -----------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Time.format(Units.twelveHourClock ? "hh:mm" : "HH:mm")
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 1.6).weight(Font.Bold).build()
            }

            SessionButton {
                icon: "logout"
                onClicked: root.exec(Config.session.commands.logout)
            }
            SessionButton {
                icon: "lock"
                onClicked: {
                    root.screenState.controls = false;
                    root.ipc("lock", "lock");
                }
            }
            HoldButton {
                icon: "restart_alt"
                command: Config.session.commands.reboot
            }
            HoldButton {
                icon: "power_settings_new"
                command: Config.session.commands.shutdown
            }
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Time.format("dddd, MMM d, yyyy")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }

            StyledRect {
                visible: root.battery?.isLaptopBattery ?? false
                implicitWidth: batteryRow.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: batteryRow.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainer

                RowLayout {
                    id: batteryRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: root.battery?.state === UPowerDeviceState.Charging ? "battery_charging_full" : "battery_full"
                        color: root.battery?.state === UPowerDeviceState.Charging ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        text: `${Math.round((root.battery?.percentage ?? 0) * 100)}%`
                        font: Tokens.font.body.small
                    }
                }
            }
        }

        // --- connect ---------------------------------------------------------
        Section {
            text: Tr.tr("Connect")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Tile {
                Layout.fillWidth: true
                icon: "wifi"
                title: Tr.tr("Wi-Fi")
                checked: Nmcli.wifiEnabled
                subtitle: !Nmcli.wifiEnabled ? Tr.tr("Off") : (Nmcli.active?.ssid ?? Tr.tr("On"))
                onClicked: Nmcli.toggleWifi()
            }
            Tile {
                Layout.fillWidth: true
                icon: "bluetooth"
                title: Tr.tr("Bluetooth")
                checked: root.btOn
                disabled: !root.bt
                onClicked: root.bt.enabled = !root.bt.enabled
            }
            Tile {
                Layout.fillWidth: true
                icon: "flight"
                title: Tr.tr("Airplane")
                checked: !Nmcli.wifiEnabled && !root.btOn
                onClicked: {
                    const on = !checked;
                    Nmcli.enableWifi(!on);
                    if (root.bt)
                        root.bt.enabled = !on;
                }
            }
            Tile {
                Layout.fillWidth: true
                icon: "nightlight"
                title: Tr.tr("Night light")
                checked: NightLight.enabled
                onClicked: NightLight.toggle()
            }
            Tile {
                Layout.fillWidth: true
                icon: "coffee"
                title: Tr.tr("Keep awake")
                checked: IdleInhibitor.enabled
                onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
            }
            Tile {
                Layout.fillWidth: true
                icon: "do_not_disturb_on"
                title: Tr.tr("Do not disturb")
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Tile {
                Layout.fillWidth: true
                icon: "sports_esports"
                title: Tr.tr("Gaming")
                checked: GameMode.enabled
                onClicked: GameMode.enabled = !GameMode.enabled
            }
        }

        // --- sound & display ---------------------------------------------------
        Section {
            text: Tr.tr("Sound & display")
        }

        SliderRow {
            icon: Audio.muted ? "volume_off" : "volume_up"
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
        }
        SliderRow {
            icon: Audio.sourceMuted ? "mic_off" : "mic"
            value: Audio.sourceVolume
            onMoved: v => Audio.setSourceVolume(v)
        }
        SliderRow {
            visible: !!root.monitor
            icon: "brightness_6"
            value: root.monitor?.brightness ?? 0
            onMoved: v => root.monitor?.setBrightness(v)
        }

        // --- calendar ------------------------------------------------------------
        Section {
            text: Tr.tr("Calendar")
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: calendar.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            Dash.Calendar {
                id: calendar

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                screenState: root.screenState
            }
        }

        // --- tiling layout -----------------------------------------------------
        Section {
            text: Tr.tr("Layout")
        }

        Segmented {
            Layout.fillWidth: true
            options: Layouts.layouts.map(l => ({
                        id: l,
                        label: l.charAt(0).toUpperCase() + l.slice(1)
                    }))
            current: Layouts.current
            onChose: id => Layouts.choose(id)
        }

        // --- power profile -------------------------------------------------------
        Section {
            text: Tr.tr("Power")
        }

        Segmented {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.padding.large
            options: [
                {
                    id: PowerProfile.PowerSaver,
                    label: Tr.tr("Saver")
                },
                {
                    id: PowerProfile.Balanced,
                    label: Tr.tr("Balanced")
                },
                {
                    id: PowerProfile.Performance,
                    label: Tr.tr("Performance"),
                    enabled: PowerProfiles.hasPerformanceProfile
                }
            ]
            current: PowerProfiles.profile
            onChose: id => PowerProfiles.profile = id
        }
    }

    component Section: RowLayout {
        property alias text: label.text

        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.medium

        StyledText {
            id: label

            text: ""
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    component SliderRow: RowLayout {
        id: sliderRow

        required property string icon
        property real value

        signal moved(real v)

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: sliderRow.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledSlider {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3
            value: sliderRow.value
            onInteraction: v => sliderRow.moved(v)
        }

        StyledText {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(sliderRow.value * 100)}%`
            font: Tokens.font.body.small
        }
    }

    component SessionButton: IconButton {
        type: IconButton.Tonal
    }

    // Reboot / power off fire only after a 700 ms hold, like Ryoku's
    // QsHoldButton; the bar along the bottom fills while held.
    component HoldButton: SessionButton {
        id: hold

        required property list<string> command

        onPressedChanged: pressed ? holdTimer.restart() : holdTimer.stop()

        Timer {
            id: holdTimer

            interval: 700
            onTriggered: root.exec(hold.command)
        }

        StyledRect {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            implicitHeight: 3
            implicitWidth: holdTimer.running ? parent.width : 0
            radius: Tokens.rounding.full
            color: Colours.palette.m3error

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: holdTimer.running ? holdTimer.interval : 0
                }
            }
        }
    }
}
