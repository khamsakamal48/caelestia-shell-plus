pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

// Claude plan usage, from assets/claude_usage.py (Claude Code's own login and /usage endpoint)
Item {
    id: root

    property var usage: null
    property real now: Date.now() / 1000
    readonly property int maxDay: Math.max(1, ...(usage?.days ?? []).map(d => d.tokens))

    function countdown(reset: real): string {
        const s = Math.max(0, reset - now);
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        // TRANSLATORS: time until a usage limit resets, e.g. "Resets in 2d 4h"
        return Tr.tr("Resets in %1").arg(d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`);
    }

    function tokens(n: real): string {
        return n >= 1e9 ? `${(n / 1e9).toFixed(1)}B` : n >= 1e6 ? `${(n / 1e6).toFixed(1)}M` : n >= 1e3 ? `${Math.round(n / 1e3)}K` : `${n}`;
    }

    implicitWidth: Tokens.sizes.dashboard.perfPlaceholderWidth
    implicitHeight: card.implicitHeight

    Process {
        id: fetcher

        command: [`${Quickshell.shellDir}/assets/claude_usage.py`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.usage = JSON.parse(text);
                } catch (e) {
                    root.usage = {
                        error: "fetch"
                    };
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 120000
        onTriggered: fetcher.running = true
    }

    Timer {
        running: true
        repeat: true
        interval: 30000
        onTriggered: root.now = Date.now() / 1000
    }

    StyledRect {
        id: card

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            RowLayout {
                spacing: Tokens.spacing.small

                ColouredIcon {
                    source: Qt.resolvedUrl(`${Quickshell.shellDir}/assets/claude.svg`)
                    implicitSize: Math.round(Tokens.font.title.medium.pointSize * 1.6)
                    colour: Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Claude")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    visible: root.usage?.stale ?? false
                    text: Tr.tr("Not refreshed, open Claude Code to renew the login")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledText {
                visible: !!root.usage?.error || !root.usage
                text: !root.usage ? Tr.tr("Loading...") : root.usage.error === "login" ? Tr.tr("Log in to Claude Code to see your usage") : root.usage.error === "expired" ? Tr.tr("Login expired, open Claude Code to renew it") : Tr.tr("Couldn't reach Claude")
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurfaceVariant
            }

            LimitBar {
                label: Tr.tr("5-hour limit")
                limit: root.usage?.fiveHour
                accent: Colours.palette.m3primary
            }

            LimitBar {
                label: Tr.tr("Weekly limit")
                limit: root.usage?.sevenDay
                accent: Colours.palette.m3secondary
            }

            ColumnLayout {
                visible: !!root.usage?.days
                spacing: Tokens.spacing.small

                RowLayout {
                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Last 7 days")
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        // TRANSLATORS: %1 = token count, e.g. "42.1M"
                        text: Tr.tr("%1 tokens today").arg(root.tokens((root.usage?.days ?? []).slice(-1)[0]?.tokens ?? 0))
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.usage?.days ?? []

                        ColumnLayout {
                            id: day

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: Tokens.spacing.extraSmall

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 80

                                StyledRect {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    implicitHeight: Math.max(radius * 2, parent.height * day.modelData.tokens / root.maxDay)
                                    radius: Tokens.rounding.small
                                    color: day.modelData.tokens > 0 ? Colours.palette.m3tertiary : Colours.palette.m3surfaceContainerHighest
                                }
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: new Date(`${day.modelData.date}T00:00`).toLocaleDateString(Qt.locale(), "ddd")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }

    component LimitBar: ColumnLayout {
        id: bar

        required property string label
        required property var limit
        required property color accent

        visible: !!limit
        spacing: Tokens.spacing.small

        RowLayout {
            StyledText {
                text: bar.label
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Strings.percentOne(bar.limit?.percent ?? 0)
                font: Tokens.font.title.small
                color: bar.accent
            }

            StyledText {
                visible: (bar.limit?.reset ?? 0) > 0
                text: root.countdown(bar.limit?.reset ?? 0)
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.small
            value: bar.limit?.percent ?? 0
            fgColour: bar.accent
        }
    }
}
