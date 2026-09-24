pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();

        return Config.utilities.quickToggles.values.filter(item => {
            if (!item.enabled)
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.selectedProvider.length > 0;
            }

            seenIds.add(item.id);
            return true;
        });
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.tr("Quick toggles")
            font: Tokens.font.body.medium
        }

        QuickToggleRow {
            model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
            // Pad an odd split so both rows keep the same button width
            spacers: root.quickToggles.length % 2
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model
        property int spacers

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "airplane"
                    delegate: Toggle {
                        icon: "flight"
                        checked: Airplane.enabled
                        onClicked: Airplane.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "clipboard"
                    delegate: Action {
                        icon: "content_paste"
                        onClicked: {
                            root.screenState.utilities = false;
                            root.screenState.clipboard = true;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "nightLight"
                    delegate: Toggle {
                        icon: "nightlight"
                        checked: NightLight.enabled
                        onClicked: NightLight.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "launcher"
                    delegate: Action {
                        icon: "search"
                        onClicked: {
                            root.screenState.utilities = false;
                            root.screenState.launcher = true;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "screenshot"
                    delegate: Action {
                        icon: "screenshot_region"
                        onClicked: {
                            root.screenState.utilities = false;
                            // RyoShot: Ryoku's capture + annotate editor, same as Print / Super+Shift+S
                            Quickshell.execDetached(["sh", "-c", "flock -n -o /tmp/ryoshot.lock qs -c ryoshot"]);
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "colourPicker"
                    delegate: Action {
                        icon: "colorize"
                        onClicked: {
                            root.screenState.utilities = false;
                            Quickshell.execDetached(["hyprpicker", "-a"]);
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        checked: GameMode.enabled
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
            }
        }

        Repeater {
            model: parent.spacers

            Item {
                property bool fillWidth: true

                implicitWidth: 0
            }
        }
    }

    // A one-shot button (opens something) rather than an on/off toggle.
    component Action: Toggle {
        isToggle: false
        inactiveOnColour: Colours.palette.m3onSurfaceVariant
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        // Stay a pill when checked; colour alone marks the state
        checkedRadius: (height || implicitHeight) / 2 * Math.min(1, Tokens.rounding.scale)
        shapeMorph: true
    }
}
