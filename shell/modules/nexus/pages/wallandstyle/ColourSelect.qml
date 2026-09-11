pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services
import qs.modules.nexus.common

PageBase {
    id: root

    property var lightSchemes: []
    property var darkSchemes: []

    function parseSchemeList(json: string): void {
        const light = [];
        const dark = [];
        try {
            const entries = JSON.parse(json);
            for (const s of entries) {
                const entry = { name: s.name, flavour: s.flavour, mode: s.mode, colours: s.colours };
                if (String(s.mode).toLowerCase().includes("light"))
                    light.push(entry);
                else
                    dark.push(entry);
            }
        } catch (e) {
            // Leave the lists empty on parse failure.
        }
        root.lightSchemes = light;
        root.darkSchemes = dark;
    }

    title: qsTr("Colors")
    isSubPage: true

    Component.onCompleted: {
        Schemes.reload();
        schemeListProc.running = true;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledText {
            text: qsTr("Wallpapers")
            font: Tokens.font.title.medium
        }

        StyledRect {
            id: dynamicCard

            readonly property bool isSelected: Schemes.currentScheme === "dynamic"

            Layout.fillWidth: true
            implicitHeight: dynamicRow.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
            border.width: isSelected ? 2 : 1
            border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant

            StateLayer {
                radius: parent.radius
                onClicked: Colours.setScheme("dynamic")
            }

            RowLayout {
                id: dynamicRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                StyledRect {
                    Layout.preferredWidth: Tokens.sizes.launcher.itemHeight
                    Layout.preferredHeight: Tokens.sizes.launcher.itemHeight

                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outline, 0.5)
                    radius: Tokens.rounding.full
                    color: "transparent"
                    clip: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rows: 2
                        columnSpacing: 0
                        rowSpacing: 0

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.palette.m3surface
                            radius: Tokens.rounding.full
                        }
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.palette.m3primary
                            radius: Tokens.rounding.full
                        }
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.palette.m3secondary
                            radius: Tokens.rounding.full
                        }
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.palette.m3tertiary
                            radius: Tokens.rounding.full
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Dynamic")
                        font: Tokens.font.title.small
                        color: dynamicCard.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Colors that follow your wallpaper")
                        font: Tokens.font.body.medium
                        color: dynamicCard.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    visible: dynamicCard.isSelected
                    text: "check"
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Light")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: root.lightSchemes

                PaletteCard {}
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Dark")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: root.darkSchemes

                PaletteCard {}
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Scheme")
            font: Tokens.font.title.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: Schemes.variants

                StyledRect {
                    id: varDelegateRect

                    required property var modelData

                    readonly property bool isSelected: modelData?.variant === Schemes.currentVariant

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    implicitHeight: varCol.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.large
                    color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant

                    StateLayer {
                        radius: parent.radius
                        onClicked: varDelegateRect.modelData?.onClicked(null)
                    }

                    RowLayout {
                        id: varCol

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.large

                        MaterialIcon {
                            Layout.alignment: Qt.AlignTop
                            text: varDelegateRect.modelData?.icon ?? ""
                            fontStyle: Tokens.font.icon.extraLarge
                            color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                Layout.fillWidth: true
                                text: varDelegateRect.modelData?.name ?? ""
                                font: Tokens.font.title.small
                                color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: varDelegateRect.modelData?.description ?? ""
                                font: Tokens.font.body.medium
                                color: varDelegateRect.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }

        // Extracted Color Palette Inspector subpage button
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            implicitHeight: allColorsRow.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            StateLayer {
                anchors.fill: parent
                radius: parent.radius
                onClicked: root.nState.openSubPage(11)
            }

            RowLayout {
                id: allColorsRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                MaterialIcon {
                    text: "palette"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3onSurface
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: qsTr("Extracted Color Palette Inspector")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }
                    StyledText {
                        text: qsTr("View all extracted tokens and copyable hex codes")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    fontStyle: Tokens.font.icon.large
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Advanced color settings subpage button
        StyledRect {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraLarge
            implicitHeight: row.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            StateLayer {
                anchors.fill: parent
                radius: parent.radius
                onClicked: root.nState.openSubPage(9)
            }

            RowLayout {
                id: row

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                MaterialIcon {
                    text: "settings_suggest"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3onSurface
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: qsTr("Advanced color settings")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }
                    StyledText {
                        text: qsTr("Material You engine, terminal and window decoration options")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    fontStyle: Tokens.font.icon.large
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Process {
            id: schemeListProc

            command: ["python3", Quickshell.shellPath("scripts/scheme-list.py")]
            stdout: StdioCollector {
                onStreamFinished: root.parseSchemeList(text)
            }
        }
    }

    component PaletteCard: StyledRect {
        id: card

        required property var modelData

        readonly property bool isSelected: `${modelData?.name} ${modelData?.flavour}` === Schemes.currentScheme && ((modelData?.mode === "light") === Colours.light)

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: cardRow.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: isSelected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        border.width: isSelected ? 2 : 1
        border.color: isSelected ? Colours.palette.m3secondary : Colours.palette.m3surfaceVariant

        StateLayer {
            radius: parent.radius
            onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "-n", card.modelData.name, "-f", card.modelData.flavour, "-m", card.modelData.mode])
        }

        RowLayout {
            id: cardRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            StyledRect {
                Layout.preferredWidth: Tokens.sizes.launcher.itemHeight
                Layout.preferredHeight: Tokens.sizes.launcher.itemHeight

                border.width: 1
                border.color: Qt.alpha(`#${card.modelData?.colours?.outline}`, 0.5)
                color: `#${card.modelData?.colours?.surface}`
                radius: Tokens.rounding.full

                Item {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    width: parent.width / 2
                    clip: true

                    StyledRect {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right

                        width: parent.width
                        color: `#${card.modelData?.colours?.primary}`
                        radius: Tokens.rounding.full
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData?.flavour ?? ""
                    font: Tokens.font.title.small
                    color: card.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                }
                StyledText {
                    Layout.fillWidth: true
                    text: card.modelData?.name ?? ""
                    font: Tokens.font.body.medium
                    color: card.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: card.isSelected
                text: "check"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }
    }
}
