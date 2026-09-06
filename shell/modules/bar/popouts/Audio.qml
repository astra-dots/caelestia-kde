pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: GlobalConfig.bar.perElementPreviewScale ? (!isNaN(GlobalConfig.bar.previewScales.audio) ? GlobalConfig.bar.previewScales.audio : 0.0) : 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real elementFontOffset: GlobalConfig.bar.perElementFontScale ? (!isNaN(GlobalConfig.bar.previewFontScales.audio) ? GlobalConfig.bar.previewFontScales.audio : 0.0) : 0.0
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0) + elementFontOffset)

    readonly property bool hasInput: Audio.sources.length > 0
    width: Math.max((hasInput ? 580 : 300) * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    implicitWidth: width
    spacing: Tokens.spacing.medium * scaleOffset

    readonly property real cardHeight: Math.max(outputLayout.implicitHeight, (root.hasInput ? inputLayout.implicitHeight : 0)) + Tokens.padding.medium * 2 * root.scaleOffset

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    // Title Row: Audio Title + Settings Button
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        Layout.rightMargin: Tokens.padding.small * root.scaleOffset

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Audio")
            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
        }

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: "settings"
            font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
            onClicked: root.popouts.detachRequested("audio")
        }
    }

    // Device Cards Row: Left Output Card, Right Input Card (Both matched to exact same height)
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium * root.scaleOffset

        // Left Card: Output Devices
        StyledRect {
            id: outputCard

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            implicitHeight: root.cardHeight
            radius: Tokens.rounding.medium * root.scaleOffset
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            ColumnLayout {
                id: outputLayout

                width: parent.width - Tokens.padding.medium * 2 * root.scaleOffset
                x: Tokens.padding.medium * root.scaleOffset
                y: Tokens.padding.medium * root.scaleOffset
                spacing: Tokens.spacing.medium * root.scaleOffset

                StyledText {
                    text: qsTr("Output device")
                    font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                }

                Repeater {
                    model: Audio.sinks

                    StyledRadioButton {
                        id: outputControl

                        required property PwNode modelData

                        Layout.fillWidth: true
                        Layout.maximumWidth: outputLayout.width
                        width: outputLayout.width

                        ButtonGroup.group: sinks
                        checked: Audio.sink?.id === modelData.id
                        onClicked: Audio.setAudioSink(modelData)
                        text: modelData.description
                        font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()

                        contentItem: MarqueeText {
                            anchors.left: parent.left
                            anchors.leftMargin: (outputControl.indicator ? outputControl.indicator.implicitWidth : 20) + Tokens.spacing.medium * root.scaleOffset
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                            anchors.verticalCenter: parent.verticalCenter
                            text: outputControl.text
                            font: outputControl.font
                            alwaysScroll: true
                            externalHovered: outputControl.hovered
                            color: outputControl.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: outputControl.click()
                            }
                        }
                    }
                }
            }
        }

        // Right Card: Input Devices
        StyledRect {
            id: inputCard

            visible: root.hasInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            implicitHeight: root.cardHeight
            radius: Tokens.rounding.medium * root.scaleOffset
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            ColumnLayout {
                id: inputLayout

                width: parent.width - Tokens.padding.medium * 2 * root.scaleOffset
                x: Tokens.padding.medium * root.scaleOffset
                y: Tokens.padding.medium * root.scaleOffset
                spacing: Tokens.spacing.medium * root.scaleOffset

                StyledText {
                    text: qsTr("Input device")
                    font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                }

                Repeater {
                    model: Audio.sources

                    StyledRadioButton {
                        id: inputControl

                        required property PwNode modelData

                        Layout.fillWidth: true
                        Layout.maximumWidth: inputLayout.width
                        width: inputLayout.width

                        ButtonGroup.group: sources
                        checked: Audio.source?.id === modelData.id
                        onClicked: Audio.setAudioSource(modelData)
                        text: modelData.description
                        font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()

                        contentItem: MarqueeText {
                            anchors.left: parent.left
                            anchors.leftMargin: (inputControl.indicator ? inputControl.indicator.implicitWidth : 20) + Tokens.spacing.medium * root.scaleOffset
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.padding.extraSmall * root.scaleOffset
                            anchors.verticalCenter: parent.verticalCenter
                            text: inputControl.text
                            font: inputControl.font
                            alwaysScroll: true
                            externalHovered: inputControl.hovered
                            color: inputControl.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: inputControl.click()
                            }
                        }
                    }
                }
            }
        }
    }

    // Sliders Row: Volume on Left, Microphone on Right (Guaranteed identical vertical height)
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium * root.scaleOffset

        // Left: Volume
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: Tokens.spacing.small * root.scaleOffset

            StyledText {
                Layout.topMargin: Tokens.spacing.small * root.scaleOffset
                text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
                font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Math.round(26 * root.scaleOffset)

                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: Math.round(10 * root.scaleOffset)

                    value: Audio.volume
                    onInteraction: v => Audio.setVolume(v)
                    onReleased: v => Audio.playEffectTick()
                }
            }
        }

        // Right: Microphone
        ColumnLayout {
            visible: root.hasInput
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: Tokens.spacing.small * root.scaleOffset

            StyledText {
                Layout.topMargin: Tokens.spacing.small * root.scaleOffset
                text: qsTr("Microphone (%1)").arg(Audio.sourceMuted ? qsTr("Muted") : `${Math.round(Audio.sourceVolume * 100)}%`)
                font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Math.round(26 * root.scaleOffset)

                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: Math.round(10 * root.scaleOffset)

                    value: Audio.sourceVolume
                    onInteraction: v => Audio.setSourceVolume(v)
                }
            }
        }
    }
}
