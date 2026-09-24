pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

// Clipboard history drawer (Super+V): full height, sliding out from the bar on
// the left edge. Same open/close model as the sidebar
// (modules/sidebar/Wrapper.qml).
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.clipboard
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.leftMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
