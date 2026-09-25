pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias view: view
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    // Past bar.tray.maxIcons (0 = no cap) the icons scroll, so a crowded tray
    // can't push the clock and status icons off the bar.
    readonly property real iconHeight: items.count > 0 ? items.itemAt(0)?.implicitHeight ?? 0 : 0
    readonly property real maxViewHeight: Config.bar.tray.maxIcons > 0 ? Config.bar.tray.maxIcons * (iconHeight + layout.spacing) - layout.spacing : Infinity
    readonly property bool canScroll: layout.implicitHeight > maxViewHeight

    function scroll(delta: real): void {
        view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, view.contentY - delta / 120 * (iconHeight + layout.spacing)));
    }

    readonly property real nonAnimHeight: {
        if (!Config.bar.tray.compact)
            return view.height + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandIcon.implicitHeight + view.height + spacing + pad;
        return Math.max(Config.bar.tray.background ? width : 0, expandIcon.implicitHeight + pad);
    }

    clip: true
    visible: height > 0

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Flickable {
        id: view

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        width: layout.implicitWidth
        height: Math.min(layout.implicitHeight, root.maxViewHeight)
        contentHeight: layout.implicitHeight
        interactive: false // the bar routes the wheel here (Bar.handleWheel)
        clip: true
        onHeightChanged: root.scroll(0) // clamp when icons leave

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

        Behavior on contentY {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Column {
            id: layout

            spacing: Tokens.spacing.small

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                id: items

                model: ScriptModel {
                    values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
                }

                TrayItem {}
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
