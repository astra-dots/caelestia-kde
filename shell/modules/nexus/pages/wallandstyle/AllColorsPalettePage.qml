pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Extracted Palette Inspector")
    isSubPage: true

    function copyHex(name: string, colorVal: color): void {
        const hex = colorVal.toString().toUpperCase();
        Quickshell.clipboardText = hex;
        if (typeof Toaster !== "undefined" && Toaster.toast) {
            Toaster.toast(qsTr("Copied to clipboard"), `${name}: ${hex}`, "palette");
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.padding.extraSmall
        }

        // Section 1: Core Material 3 Accents & Roles
        StyledText {
            Layout.topMargin: Tokens.spacing.small
            text: qsTr("Core Material 3 Accents")
            font: Tokens.font.title.medium
            color: Colours.palette.m3primary
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.small
            columnSpacing: Tokens.spacing.small

            Repeater {
                model: [
                    { name: "Primary", col: Colours.palette.m3primary, desc: "Main accent & active elements" },
                    { name: "On Primary", col: Colours.palette.m3onPrimary, desc: "Content & icons on primary" },
                    { name: "Primary Container", col: Colours.palette.m3primaryContainer, desc: "Tonal fills & slider bars" },
                    { name: "On Primary Container", col: Colours.palette.m3onPrimaryContainer, desc: "Text on primary container" },
                    { name: "Inverse Primary", col: Colours.palette.m3inversePrimary, desc: "Inverse state accent" },
                    { name: "Secondary", col: Colours.palette.m3secondary, desc: "Secondary complementary accent" },
                    { name: "On Secondary", col: Colours.palette.m3onSecondary, desc: "Content on secondary" },
                    { name: "Secondary Container", col: Colours.palette.m3secondaryContainer, desc: "Card accents, pills & badges" },
                    { name: "On Secondary Container", col: Colours.palette.m3onSecondaryContainer, desc: "Text on secondary container" },
                    { name: "Tertiary", col: Colours.palette.m3tertiary, desc: "Contrasting highlight accent" },
                    { name: "On Tertiary", col: Colours.palette.m3onTertiary, desc: "Content on tertiary" },
                    { name: "Tertiary Container", col: Colours.palette.m3tertiaryContainer, desc: "Soft tertiary container & badges" },
                    { name: "On Tertiary Container", col: Colours.palette.m3onTertiaryContainer, desc: "Text on tertiary container" },
                    { name: "Error", col: Colours.palette.m3error, desc: "Warnings, alerts & errors" },
                    { name: "On Error", col: Colours.palette.m3onError, desc: "Content on error" },
                    { name: "Error Container", col: Colours.palette.m3errorContainer, desc: "Soft error container background" },
                    { name: "Success", col: Colours.palette.m3success, desc: "Success & confirmation actions" },
                    { name: "Success Container", col: Colours.palette.m3successContainer, desc: "Soft success background" }
                ]

                delegate: ColorCardItem {
                    required property var modelData
                    Layout.fillWidth: true
                    cardName: modelData.name
                    cardColor: modelData.col
                    cardDesc: modelData.desc
                    onClicked: root.copyHex(modelData.name, modelData.col)
                }
            }
        }

        // Section 2: Surface & Container Elevations
        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: qsTr("Surfaces & Elevation Tiers")
            font: Tokens.font.title.medium
            color: Colours.palette.m3primary
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.small
            columnSpacing: Tokens.spacing.small

            Repeater {
                model: [
                    { name: "Background", col: Colours.palette.m3background, desc: "Base window background" },
                    { name: "On Background", col: Colours.palette.m3onBackground, desc: "Text on base background" },
                    { name: "Surface", col: Colours.palette.m3surface, desc: "Standard surface elevation" },
                    { name: "On Surface", col: Colours.palette.m3onSurface, desc: "Main text headers & labels" },
                    { name: "On Surface Variant", col: Colours.palette.m3onSurfaceVariant, desc: "Subtitles & secondary text" },
                    { name: "Surface Dim", col: Colours.palette.m3surfaceDim, desc: "Dimmed background surface" },
                    { name: "Surface Bright", col: Colours.palette.m3surfaceBright, desc: "Bright surface elevation" },
                    { name: "Container Lowest", col: Colours.palette.m3surfaceContainerLowest, desc: "Lowest surface container tier" },
                    { name: "Container Low", col: Colours.palette.m3surfaceContainerLow, desc: "Low surface container tier" },
                    { name: "Container", col: Colours.palette.m3surfaceContainer, desc: "Standard surface container" },
                    { name: "Container High", col: Colours.palette.m3surfaceContainerHigh, desc: "Elevated card surface" },
                    { name: "Container Highest", col: Colours.palette.m3surfaceContainerHighest, desc: "Highest elevation surface" },
                    { name: "Inverse Surface", col: Colours.palette.m3inverseSurface, desc: "Inverted contrast surface" },
                    { name: "Outline", col: Colours.palette.m3outline, desc: "Borders, outlines & dividers" },
                    { name: "Outline Variant", col: Colours.palette.m3outlineVariant, desc: "Subtle dividers & borders" },
                    { name: "Surface Tint", col: Colours.palette.m3surfaceTint, desc: "Elevation tint overlay" }
                ]

                delegate: ColorCardItem {
                    required property var modelData
                    Layout.fillWidth: true
                    cardName: modelData.name
                    cardColor: modelData.col
                    cardDesc: modelData.desc
                    onClicked: root.copyHex(modelData.name, modelData.col)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.padding.large
        }
    }

    component ColorCardItem: StyledRect {
        id: cardRoot

        property string cardName: ""
        property color cardColor: "transparent"
        property string cardDesc: ""
        property bool copied: false
        signal clicked()

        Timer {
            id: copiedTimer
            interval: 1400
            onTriggered: cardRoot.copied = false
        }

        implicitHeight: 54
        radius: Tokens.rounding.medium
        color: cardRoot.copied ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer
        border.color: cardRoot.copied ? Colours.palette.m3primary : "transparent"
        border.width: cardRoot.copied ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        StateLayer {
            anchors.fill: parent
            radius: parent.radius
            onClicked: {
                cardRoot.copied = true;
                copiedTimer.restart();
                cardRoot.clicked();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            // Pure Clean Color Swatch Box (No Icon Inside)
            Rectangle {
                width: 36
                height: 36
                radius: Tokens.rounding.small
                color: cardRoot.cardColor
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: cardRoot.cardName
                    font: Tokens.font.body.small
                    color: cardRoot.copied ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: cardRoot.copied ? qsTr("Copied to clipboard") : cardRoot.cardColor.toString().toUpperCase()
                    font: Tokens.font.label.small
                    color: cardRoot.copied ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            // Right-Aligned Copy / Check Icon
            MaterialIcon {
                text: cardRoot.copied ? "check" : "content_copy"
                fontStyle: Tokens.font.icon.small
                color: cardRoot.copied ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                opacity: cardRoot.copied ? 1 : 0.6
            }
        }
    }
}
