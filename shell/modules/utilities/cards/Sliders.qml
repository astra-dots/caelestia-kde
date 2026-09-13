pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    readonly property var monitor: (Brightness.monitors && Brightness.monitors.length > 0) ? Brightness.monitors[0] : null
    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property real brightness: root.monitor ? root.monitor.brightness : 0

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    property var visibilities: null
    readonly property bool isUtilitiesOpen: visibilities ? visibilities.utilities : false

    onIsUtilitiesOpenChanged: {
        if (isUtilitiesOpen && root.monitor && typeof root.monitor.fetchBrightness === "function") {
            root.monitor.fetchBrightness();
        }
    }

    Timer {
        id: openPollTimer
        interval: 1000
        repeat: true
        running: root.isUtilitiesOpen && (root.monitor?.isDdc ?? false)
        onTriggered: {
            if (root.monitor && typeof root.monitor.fetchBrightness === "function") {
                root.monitor.fetchBrightness();
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        // Volume Row
        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: 34

            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            RowLayout {
                anchors.fill: parent
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Icons.getVolumeIcon(root.volume, root.muted)
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.small.size(20).build()
                }

                StyledSlider {
                    id: volumeSlider

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    from: 0
                    to: GlobalConfig.services.maxVolume
                    value: root.volume
                    onMoved: Audio.setVolume(value)
                }

                StyledText {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(root.volume * 100)}%`
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    color: Colours.palette.m3secondary
                    renderType: Text.QtRendering
                }
            }
        }

        // Brightness Row
        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: 34

            function onWheel(event: WheelEvent) {
                if (!root.monitor)
                    return;
                if (event.angleDelta.y > 0)
                    root.monitor.setBrightness(root.monitor.brightness + GlobalConfig.services.brightnessIncrement);
                else if (event.angleDelta.y < 0)
                    root.monitor.setBrightness(root.monitor.brightness - GlobalConfig.services.brightnessIncrement);
            }

            RowLayout {
                anchors.fill: parent
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: HyprSunset.active ? "bedtime" : `brightness_${Math.min(7, Math.max(1, Math.round(root.brightness * 6) + 1))}`
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.small.size(20).build()
                }

                StyledSlider {
                    id: brightnessSlider

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    from: 0
                    to: 1.0
                    value: root.brightness
                    onMoved: {
                        if (root.monitor)
                            root.monitor.setBrightness(value);
                    }
                }

                StyledText {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(root.brightness * 100)}%`
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    color: Colours.palette.m3secondary
                    renderType: Text.QtRendering
                }
            }
        }
    }
}
