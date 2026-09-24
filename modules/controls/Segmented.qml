pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// A pill of mutually exclusive choices (after Ryoku's QsSeg), used for the
// tiling layout and the power profile.
StyledRect {
    id: root

    // [{ id, label, enabled? }]
    required property var options
    property var current

    signal chose(var id)

    implicitHeight: 44
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
            model: root.options

            delegate: StyledRect {
                id: seg

                required property var modelData
                readonly property bool selected: modelData.id === root.current
                readonly property bool usable: modelData.enabled !== false

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Tokens.rounding.full
                color: selected ? Colours.palette.m3primary : "transparent"
                opacity: usable ? 1 : 0.4

                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    radius: seg.radius
                    disabled: !seg.usable
                    color: seg.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    onClicked: root.chose(seg.modelData.id)
                }

                StyledText {
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                }
            }
        }
    }
}
