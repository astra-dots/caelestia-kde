pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property Brightness.Monitor monitor
    required property DrawerVisibilities visibilities
    required property string activeIndicator

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    readonly property real currentValue: {
        if (root.activeIndicator === "brightness")
            return root.brightness;
        if (root.activeIndicator === "microphone")
            return root.sourceVolume;
        return root.volume;
    }

    readonly property bool isMuted: {
        if (root.activeIndicator === "microphone")
            return root.sourceMuted;
        if (root.activeIndicator === "volume")
            return root.muted;
        return false;
    }

    readonly property string icon: {
        if (root.activeIndicator === "brightness")
            return HyprSunset.active ? "bedtime" : `brightness_${Math.min(7, Math.max(1, Math.round(root.brightness * 6) + 1))}`;
        if (root.activeIndicator === "microphone")
            return Icons.getMicVolumeIcon(root.sourceVolume, root.sourceMuted);
        return Icons.getVolumeIcon(root.volume, root.muted);
    }

    readonly property string title: {
        if (root.activeIndicator === "brightness")
            return qsTr("Brightness");
        if (root.activeIndicator === "microphone")
            return qsTr("Microphone");
        return qsTr("Volume");
    }

    implicitWidth: 380
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Left Icon Badge
        StyledRect {
            implicitWidth: 38
            implicitHeight: 38
            Layout.alignment: Qt.AlignVCenter

            radius: Tokens.rounding.full
            color: root.isMuted ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                color: root.isMuted ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
                fontStyle: Tokens.font.icon.builders.medium.size(20).build()
            }
        }

        // Right Info Section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    color: Colours.palette.m3onSurface
                    renderType: Text.QtRendering
                }

                StyledText {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(root.currentValue * 100)}%`
                    font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    color: root.isMuted ? Colours.palette.m3error : Colours.palette.m3secondary
                    renderType: Text.QtRendering
                }
            }

            // Progress Bar Track
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHighest
                clip: true

                StyledRect {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    implicitWidth: parent.width * Math.min(1.0, Math.max(0.0, root.currentValue))
                    radius: parent.radius
                    color: root.isMuted ? Colours.palette.m3error : Colours.palette.m3primary

                    Behavior on implicitWidth {
                        Anim {
                            type: Anim.StandardSmall
                        }
                    }
                }
            }
        }
    }
}
