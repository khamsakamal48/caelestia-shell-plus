import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// A Connect tile (after Ryoku's QsTile): icon disc, title and a state line,
// tinted while on.
StyledRect {
    id: root

    required property string icon
    required property string title
    property string subtitle: checked ? Tr.tr("On") : Tr.tr("Off")
    property bool checked
    property bool disabled

    signal clicked

    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: checked ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
    opacity: disabled ? 0.5 : 1

    Behavior on color {
        CAnim {}
    }

    StateLayer {
        radius: root.radius
        disabled: root.disabled
        color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.icon
                fill: root.checked ? 1 : 0
                color: root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                elide: Text.ElideRight
                color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }
    }
}
