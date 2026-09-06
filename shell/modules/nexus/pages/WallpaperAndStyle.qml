pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Appearance")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: Wallpapers.current
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        // Connected Material You Palette Split-Capsule with Fluid Hover Tooltip & Live Copy Feedback
        Item {
            id: paletteCapsuleContainer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: wallWrapper.implicitWidth
            implicitWidth: wallWrapper.implicitWidth
            implicitHeight: 36

            property int hoveredIdx: -1
            property string hoveredName: ""
            property string hoveredHex: ""
            property string lastCopiedText: ""
            property real tooltipTargetX: 0

            Timer {
                id: copiedAnimTimer
                interval: 1400
                onTriggered: {
                    paletteCapsuleContainer.lastCopiedText = "";
                }
            }

            // Fluid Floating Tooltip Badge
            Rectangle {
                id: tooltipBadge
                z: 10
                anchors.bottom: capsuleRow.top
                anchors.bottomMargin: 6
                x: Math.max(0, Math.min(paletteCapsuleContainer.width - width, paletteCapsuleContainer.tooltipTargetX - width / 2))
                implicitWidth: badgeContent.implicitWidth + 16
                implicitHeight: 24
                radius: 12
                color: paletteCapsuleContainer.lastCopiedText !== "" ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                opacity: (paletteCapsuleContainer.hoveredIdx >= 0 || paletteCapsuleContainer.lastCopiedText !== "") ? 1 : 0
                scale: (paletteCapsuleContainer.hoveredIdx >= 0 || paletteCapsuleContainer.lastCopiedText !== "") ? 1 : 0.85

                Behavior on opacity {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
                Behavior on x {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    id: badgeContent
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        visible: paletteCapsuleContainer.lastCopiedText !== ""
                        text: "check"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3onPrimaryContainer
                    }

                    StyledText {
                        text: {
                            if (paletteCapsuleContainer.lastCopiedText !== "") {
                                return `${paletteCapsuleContainer.lastCopiedText} Copied!`;
                            }
                            if (paletteCapsuleContainer.hoveredIdx >= 0) {
                                return `${paletteCapsuleContainer.hoveredName} • ${paletteCapsuleContainer.hoveredHex}`;
                            }
                            return "";
                        }
                        font: Tokens.font.label.small
                        color: paletteCapsuleContainer.lastCopiedText !== "" ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }

            RowLayout {
                id: capsuleRow
                anchors.fill: parent
                spacing: 4

                // Left Pill: Color Swatches with true rounded outer corners and slight inner corner curve
                ClippingRectangle {
                    id: ribbonBar
                    Layout.fillWidth: true
                    implicitHeight: 36
                    topLeftRadius: 18
                    bottomLeftRadius: 18
                    topRightRadius: 4
                    bottomRightRadius: 4

                    readonly property var swatches: [
                        { name: "Primary", col: Colours.palette.m3primary },
                        { name: "Primary Container", col: Colours.palette.m3primaryContainer },
                        { name: "Secondary", col: Colours.palette.m3secondary },
                        { name: "Secondary Container", col: Colours.palette.m3secondaryContainer },
                        { name: "Tertiary", col: Colours.palette.m3tertiary },
                        { name: "Tertiary Container", col: Colours.palette.m3tertiaryContainer },
                        { name: "Surface Container", col: Colours.palette.m3surfaceContainerHigh },
                        { name: "Outline", col: Colours.palette.m3outline }
                    ]

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: ribbonBar.swatches
                            delegate: Rectangle {
                                id: swatchSeg
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: swatchSeg.modelData.col

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        paletteCapsuleContainer.hoveredIdx = swatchSeg.index;
                                        paletteCapsuleContainer.hoveredName = swatchSeg.modelData.name;
                                        paletteCapsuleContainer.hoveredHex = swatchSeg.modelData.col.toString().toUpperCase();
                                        paletteCapsuleContainer.tooltipTargetX = swatchSeg.x + swatchSeg.width / 2;
                                    }
                                    onExited: {
                                        if (paletteCapsuleContainer.hoveredIdx === swatchSeg.index) {
                                            paletteCapsuleContainer.hoveredIdx = -1;
                                        }
                                    }
                                    onClicked: {
                                        const hex = swatchSeg.modelData.col.toString().toUpperCase();
                                        Quickshell.clipboardText = hex;
                                        paletteCapsuleContainer.lastCopiedText = hex;
                                        copiedAnimTimer.restart();
                                        if (typeof Toaster !== "undefined" && Toaster.toast) {
                                            Toaster.toast(qsTr("Copied to clipboard"), `${swatchSeg.modelData.name}: ${hex}`, "palette");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Right Split Button: Connected All Colors Button with slight inner curve & rounded outer edge
                ClippingRectangle {
                    id: allColorsBtn
                    implicitWidth: btnContent.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: 36
                    color: Colours.palette.m3secondaryContainer
                    topLeftRadius: 4
                    bottomLeftRadius: 4
                    topRightRadius: 18
                    bottomRightRadius: 18

                    StateLayer {
                        anchors.fill: parent
                        radius: parent.radius
                        onClicked: root.nState.openSubPage(10) // All Colors Inspector Subpage
                    }

                    RowLayout {
                        id: btnContent
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: "palette"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            text: qsTr("All Colors")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "image_search"
                text: qsTr("Wallhaven")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(4) // Wallhaven page
            }

            IconTextButton {
                icon: "palette"
                text: Strings.localizeEnglishSpelling(qsTr("Colours"))
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        SectionHeader {
            text: qsTr("Settings")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                icon: "settings_suggest"
                label: qsTr("Wallpaper Settings")
                status: qsTr("Display, Recolour, Desktop Icons")
                onClicked: root.nState.openSubPage(5)
            }

            NavRow {
                icon: "slideshow"
                label: qsTr("Slideshow & Order")
                status: qsTr("Slideshow interval and randomization")
                onClicked: root.nState.openSubPage(6)
            }

            NavRow {
                last: true
                icon: "style"
                label: qsTr("Theme & Effects")
                status: qsTr("Islands, Pitch Black, Transparency, Dark Theme")
                onClicked: root.nState.openSubPage(8)
            }
        }
    }
}
