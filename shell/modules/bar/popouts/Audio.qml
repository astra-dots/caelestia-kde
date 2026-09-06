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
    width: Math.max((hasInput ? 520 : 270) * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    spacing: Tokens.spacing.medium * scaleOffset

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

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

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium * root.scaleOffset

        // Left Column: Output Device & Volume
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.small * root.scaleOffset

            StyledRect {
                Layout.fillWidth: true
                implicitWidth: outputLayout.implicitWidth + Tokens.padding.medium * 2 * root.scaleOffset
                implicitHeight: outputLayout.implicitHeight + Tokens.padding.medium * 2 * root.scaleOffset
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

                            ButtonGroup.group: sinks
                            checked: Audio.sink?.id === modelData.id
                            onClicked: Audio.setAudioSink(modelData)
                            text: modelData.description
                            font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.small * root.scaleOffset
                text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
                font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 3 * root.scaleOffset

                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: parent.implicitHeight

                    value: Audio.volume
                    onInteraction: v => Audio.setVolume(v)
                    onReleased: v => Audio.playEffectTick()
                }
            }
        }

        // Right Column: Input Device & Microphone
        ColumnLayout {
            visible: root.hasInput
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.small * root.scaleOffset

            StyledRect {
                Layout.fillWidth: true
                implicitWidth: inputLayout.implicitWidth + Tokens.padding.medium * 2 * root.scaleOffset
                implicitHeight: inputLayout.implicitHeight + Tokens.padding.medium * 2 * root.scaleOffset
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

                            ButtonGroup.group: sources
                            checked: Audio.source?.id === modelData.id
                            onClicked: Audio.setAudioSource(modelData)
                            text: modelData.description
                            font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.small * root.scaleOffset
                text: qsTr("Microphone (%1)").arg(Audio.sourceMuted ? qsTr("Muted") : `${Math.round(Audio.sourceVolume * 100)}%`)
                font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 3 * root.scaleOffset

                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: parent.implicitHeight

                    value: Audio.sourceVolume
                    onInteraction: v => Audio.setSourceVolume(v)
                }
            }
        }
    }
}
