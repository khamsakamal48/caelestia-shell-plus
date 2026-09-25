pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import "../../utils/scripts/fzf.js" as Fzf

// Clipboard history, styled like the notification sidebar: a count + title
// header, a search field, and the entries in a rounded well. Enter or a click
// copies an entry and closes; Delete removes it. Starred entries sit on top.
Item {
    id: root

    required property ScreenState screenState

    readonly property var all: [...Clipboard.stars, ...Clipboard.entries]
    readonly property var finder: new Fzf.Finder(all, {
        selector: e => e.text
    })
    readonly property var shown: {
        const q = search.text.trim();
        return q ? finder.find(q).map(r => r.item) : all;
    }

    function close(): void {
        screenState.clipboard = false;
    }

    function copy(entry: var): void {
        Clipboard.copy(entry);
        close();
    }

    Component.onCompleted: {
        Clipboard.refresh();
        search.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // --- header ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Tokens.padding.extraSmall
            spacing: Tokens.spacing.extraSmall

            StyledText {
                visible: Clipboard.entries.length > 0
                text: Clipboard.entries.length
                color: Colours.palette.m3outline
                font: Tokens.font.label.large
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Clipboard")
                color: Colours.palette.m3outline
                font: Tokens.font.label.large
                elide: Text.ElideRight
            }

            IconButton {
                visible: Clipboard.entries.length > 0
                type: IconButton.Text
                icon: "delete_sweep"
                onClicked: Clipboard.wipe()
            }
        }

        StyledTextField {
            id: search

            Layout.fillWidth: true
            leadingIcon: "search"
            placeholderText: Tr.tr("Search clipboard")

            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: if (list.currentIndex >= 0) root.copy(root.shown[list.currentIndex])
            Keys.onEnterPressed: if (list.currentIndex >= 0) root.copy(root.shown[list.currentIndex])
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Delete && list.currentIndex >= 0) {
                    Clipboard.remove(root.shown[list.currentIndex]);
                    event.accepted = true;
                }
            }
        }

        // --- entries --------------------------------------------------------
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            StyledText {
                anchors.centerIn: parent
                visible: root.shown.length === 0
                text: search.text ? Tr.tr("No matches") : Tr.tr("Nothing copied yet")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.headline.builders.small.width(90).build()
            }

            StyledListView {
                id: list

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                clip: true
                spacing: Tokens.spacing.small
                model: root.shown
                currentIndex: 0
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 150

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: list
                }

                delegate: StyledRect {
                    id: item

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: body.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.medium
                    color: ListView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer

                    StateLayer {
                        radius: item.radius
                        onClicked: root.copy(item.modelData)
                    }

                    RowLayout {
                        id: body

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        // text entry
                        StyledText {
                            Layout.fillWidth: true
                            visible: !item.modelData.image
                            text: item.modelData.text
                            maximumLineCount: 3
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            font: Tokens.font.body.medium
                        }

                        // image entry: thumbnail decoded on first view
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !!item.modelData.image
                            spacing: Tokens.spacing.extraSmall

                            Image {
                                id: thumb

                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                                asynchronous: true
                                sourceSize.height: 240
                            }

                            StyledText {
                                text: !item.modelData.image ? "" : item.modelData.starred ? item.modelData.image.ext.toUpperCase() : `${item.modelData.image.ext.toUpperCase()} · ${item.modelData.image.width}×${item.modelData.image.height}`
                                color: Colours.palette.m3outline
                                font: Tokens.font.body.small
                            }

                            Process {
                                running: !!item.modelData.image
                                command: item.modelData.image && !item.modelData.starred ? Clipboard.decodeCommand(item.modelData) : ["true"]
                                onExited: thumb.source = `file://${Clipboard.thumbnailPath(item.modelData)}`
                            }
                        }

                        IconButton {
                            Layout.alignment: Qt.AlignTop
                            type: IconButton.Text
                            icon: "star"
                            isToggle: true
                            checked: !!item.modelData.starred
                            onClicked: item.modelData.starred ? Clipboard.unstar(item.modelData) : Clipboard.star(item.modelData)
                        }

                        IconButton {
                            Layout.alignment: Qt.AlignTop
                            type: IconButton.Text
                            icon: "close"
                            onClicked: Clipboard.remove(item.modelData)
                        }
                    }
                }
            }
        }
    }
}
