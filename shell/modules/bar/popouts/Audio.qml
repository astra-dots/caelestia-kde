pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool showAppVolumes: false
    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    Connections {
        target: root.popouts
        function onCurrentNameChanged(): void {
            if (root.popouts.currentName !== "audio")
                root.showAppVolumes = false;
        }
    }

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: GlobalConfig.bar.perElementPreviewScale ? (!isNaN(GlobalConfig.bar.previewScales.audio) ? GlobalConfig.bar.previewScales.audio : 0.0) : 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real elementFontOffset: GlobalConfig.bar.perElementFontScale ? (!isNaN(GlobalConfig.bar.previewFontScales.audio) ? GlobalConfig.bar.previewFontScales.audio : 0.0) : 0.0
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0) + elementFontOffset)

    readonly property bool hasInput: Audio.sources.length > 0
    width: Math.max((root.showAppVolumes || hasInput ? 580 : 300) * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    implicitWidth: width
    spacing: Tokens.spacing.medium * scaleOffset

    readonly property real cardHeight: Math.max(outputLayout.implicitHeight, (root.hasInput ? inputLayout.implicitHeight : 0)) + Tokens.padding.medium * 2 * root.scaleOffset

    function outputIcon(node: PwNode): string {
        if (!node)
            return "speaker";
        const name = (node.description || node.name || "").toLowerCase();
        if (name.includes("headset") || name.includes("headphone") || name.includes("earbud") || name.includes("earphone"))
            return "headphones";
        return "speaker";
    }

    function sourceIcon(node: PwNode): string {
        if (!node)
            return "mic";
        const name = (node.description || node.name || "").toLowerCase();
        if (name.includes("headset"))
            return "headset_mic";
        return "mic";
    }

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    // Title Row: Audio Title / Back Button + App Volumes Button + Settings Button
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        Layout.rightMargin: Tokens.padding.small * root.scaleOffset

        IconButton {
            visible: root.showAppVolumes
            type: IconButton.Text
            isRound: true
            icon: "arrow_back"
            font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
            onClicked: root.showAppVolumes = false
        }

        StyledText {
            Layout.fillWidth: true
            text: root.showAppVolumes ? qsTr("App volumes") : qsTr("Audio")
            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
        }

        IconButton {
            id: appVolumesBtn
            visible: !root.showAppVolumes
            type: IconButton.Text
            isRound: true
            icon: "tune"
            font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
            onClicked: root.showAppVolumes = true

            Tooltip {
                target: appVolumesBtn
                text: qsTr("App Volumes (Volume Mixer)")
            }
        }

        IconButton {
            id: settingsBtn
            type: IconButton.Text
            isRound: true
            icon: "settings"
            font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
            onClicked: root.popouts.detachRequested("audio")

            Tooltip {
                target: settingsBtn
                text: qsTr("Audio Settings")
            }
        }
    }

    // Main Audio Page (Output/Input Cards + Master Volume/Mic Sliders)
    ColumnLayout {
        id: mainView

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium * root.scaleOffset
        visible: !root.showAppVolumes

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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small * root.scaleOffset

                        MaterialIcon {
                            text: root.outputIcon(Audio.sink)
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Output device")
                            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                        }
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
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }

                            TapHandler {
                                onTapped: Audio.setAudioSink(outputControl.modelData)
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small * root.scaleOffset

                        MaterialIcon {
                            text: root.sourceIcon(Audio.source)
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Input device")
                            font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                        }
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
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.NoButton
                            }

                            TapHandler {
                                onTapped: Audio.setAudioSource(inputControl.modelData)
                            }
                        }
                    }
                }
            }
        }

        // Sliders Row: Volume on Left, Microphone on Right (Guaranteed identical vertical height)
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.padding.large * root.scaleOffset
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
                    implicitHeight: Math.round(36 * root.scaleOffset)

                    onWheel: event => {
                        if (event.angleDelta.y > 0)
                            Audio.incrementVolume(0.05);
                        else if (event.angleDelta.y < 0)
                            Audio.decrementVolume(0.05);
                    }

                    StyledSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitHeight: Math.round(10 * root.scaleOffset)

                        value: Audio.volume
                        onInteraction: v => Audio.setVolume(Math.round(v * 100) / 100)
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
                    implicitHeight: Math.round(36 * root.scaleOffset)

                    onWheel: event => {
                        if (event.angleDelta.y > 0)
                            Audio.incrementSourceVolume(0.05);
                        else if (event.angleDelta.y < 0)
                            Audio.decrementSourceVolume(0.05);
                    }

                    StyledSlider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitHeight: Math.round(10 * root.scaleOffset)

                        value: Audio.sourceVolume
                        onInteraction: v => Audio.setSourceVolume(Math.round(v * 100) / 100)
                    }
                }
            }
        }
    }

    // App Volumes Page (Volume of each individual app)
    ColumnLayout {
        id: appVolumesView

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium * root.scaleOffset
        visible: root.showAppVolumes

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: appVolumesInnerLayout.implicitHeight + Tokens.padding.medium * 2 * root.scaleOffset
            radius: Tokens.rounding.medium * root.scaleOffset
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            ColumnLayout {
                id: appVolumesInnerLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium * root.scaleOffset
                spacing: Tokens.spacing.medium * root.scaleOffset

                // Empty state when no apps are playing audio
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.large * root.scaleOffset
                    Layout.bottomMargin: Tokens.padding.large * root.scaleOffset
                    spacing: Tokens.spacing.small * root.scaleOffset
                    visible: Audio.streams.length === 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "music_off"
                        fontStyle: Tokens.font.icon.large
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No apps playing audio")
                        font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Play audio in any app to adjust its volume here.")
                        font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // List of apps currently playing audio
                Flickable {
                    id: streamFlickable

                    Layout.fillWidth: true
                    implicitHeight: Math.min(300 * root.scaleOffset, streamListCol.implicitHeight)
                    contentHeight: streamListCol.implicitHeight
                    contentWidth: width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    visible: Audio.streams.length > 0

                    ScrollBar.vertical: StyledScrollBar {
                        flickable: streamFlickable
                    }

                    ColumnLayout {
                        id: streamListCol

                        width: streamFlickable.width
                        spacing: Tokens.spacing.medium * root.scaleOffset

                        Repeater {
                            model: Audio.streams

                            ColumnLayout {
                                id: streamDelegate

                                required property PwNode modelData
                                required property int index

                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall * root.scaleOffset

                                // Divider between items (except the first)
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Colours.palette.m3outlineVariant
                                    opacity: 0.3
                                    visible: streamDelegate.index > 0
                                    Layout.bottomMargin: Tokens.spacing.extraSmall * root.scaleOffset
                                }

                                // App title row: App icon + App name + Volume %
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small * root.scaleOffset

                                    IconImage {
                                        source: Quickshell.iconPath(streamDelegate.modelData?.properties?.["application.icon-name"] ?? streamDelegate.modelData?.name ?? "audio-x-generic", "audio-x-generic")
                                        implicitSize: Math.round(20 * root.scaleOffset)
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    MarqueeText {
                                        Layout.fillWidth: true
                                        text: Audio.getStreamName(streamDelegate.modelData)
                                        font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                                        alwaysScroll: true
                                    }

                                    StyledText {
                                        text: streamDelegate.modelData?.audio?.muted ? qsTr("Muted") : `${Math.round((streamDelegate.modelData?.audio?.volume ?? 0) * 100)}%`
                                        font: Tokens.font.body.builders.small.size(Tokens.font.body.small.pointSize * root.fontScale).build()
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }

                                // Slider row: Mute button + Slider
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small * root.scaleOffset

                                    IconButton {
                                        type: IconButton.Text
                                        isRound: true
                                        icon: Icons.getVolumeIcon(streamDelegate.modelData?.audio?.volume ?? 0, streamDelegate.modelData?.audio?.muted ?? false)
                                        font: Tokens.font.icon.builders.medium.size(Tokens.font.icon.medium.pointSize * root.fontScale).build()
                                        implicitWidth: Math.round(26 * root.scaleOffset)
                                        implicitHeight: Math.round(26 * root.scaleOffset)
                                        onClicked: {
                                            if (streamDelegate.modelData?.audio)
                                                Audio.setStreamMuted(streamDelegate.modelData, !streamDelegate.modelData.audio.muted);
                                        }
                                    }

                                    CustomMouseArea {
                                        Layout.fillWidth: true
                                        implicitHeight: Math.round(26 * root.scaleOffset)

                                        onWheel: event => {
                                            if (!streamDelegate.modelData?.audio) return;
                                            const cur = Math.round((streamDelegate.modelData.audio.volume ?? 0) * 100) / 100;
                                            const step = 0.05;
                                            if (event.angleDelta.y > 0)
                                                Audio.setStreamVolume(streamDelegate.modelData, Math.min(1.0, Math.round((cur + step) * 100) / 100));
                                            else if (event.angleDelta.y < 0)
                                                Audio.setStreamVolume(streamDelegate.modelData, Math.max(0.0, Math.round((cur - step) * 100) / 100));
                                        }

                                        StyledSlider {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            implicitHeight: Math.round(10 * root.scaleOffset)

                                            value: streamDelegate.modelData?.audio?.volume ?? 0
                                            onInteraction: v => Audio.setStreamVolume(streamDelegate.modelData, Math.round(v * 100) / 100)
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.round(Tokens.padding.small * root.scaleOffset)
                            visible: Audio.streams.length > 0
                        }
                    }
                }
            }
        }
    }
}
