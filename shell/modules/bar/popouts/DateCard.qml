pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, masterScale * barScaleOffset)
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0))

    readonly property real minTimeRowWidth: (timeText?.implicitWidth ?? 0) + (24 * root.scaleOffset) + (Tokens.spacing.small * root.scaleOffset)
    readonly property real minDateRowWidth: (dateText?.implicitWidth ?? 0) + (18 * root.scaleOffset) + (Tokens.spacing.small * root.scaleOffset)
    readonly property real maxContentRowWidth: Math.max(minTimeRowWidth, minDateRowWidth)
    readonly property real minContentWidth: Math.ceil(maxContentRowWidth + (Tokens.padding.large * 2 * root.scaleOffset) + (Tokens.padding.medium * root.scaleOffset))

    width: Math.max(340 * scaleOffset, minContentWidth, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    implicitWidth: width
    spacing: Tokens.spacing.small * scaleOffset

    // Live exact real-time clock updating every second
    property var currentTime: new Date()
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    readonly property string timeWithSeconds: {
        const use12 = GlobalConfig.services.useTwelveHourClock;
        return Qt.formatDateTime(root.currentTime, use12 ? "hh:mm:ss AP" : "HH:mm:ss");
    }

    readonly property string dateString: Qt.formatDateTime(root.currentTime, "dddd, MMMM d, yyyy")

    StyledText {
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        text: qsTr("Date & Time")
        font: Tokens.font.title.builders.small.size(Tokens.font.title.small.pointSize * root.fontScale).build()
        color: Colours.palette.m3onSurface
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.large * 2 * root.scaleOffset
        radius: Tokens.rounding.large * root.scaleOffset
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: cardLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large * root.scaleOffset
            spacing: Tokens.spacing.small * root.scaleOffset

            // Live Digital Time with Accurate Seconds
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small * root.scaleOffset

                MaterialIcon {
                    text: "schedule"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.medium.size(24 * root.scaleOffset).build()
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    id: timeText
                    text: root.timeWithSeconds
                    font: Tokens.font.headline.builders.small.size(Tokens.font.headline.small.pointSize * root.fontScale * 1.05).weight(Font.Medium).build()
                    color: Colours.palette.m3primary
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
                opacity: 0.4
            }

            // Full Clean Date (No Redundancy)
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small * root.scaleOffset

                MaterialIcon {
                    text: "calendar_today"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.builders.small.size(18 * root.scaleOffset).build()
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    id: dateText
                    text: root.dateString
                    font: Tokens.font.body.builders.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
