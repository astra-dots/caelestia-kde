pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    property bool _isSidebarOpen: popouts.sidebarOpen && popouts.isHorizontal

    readonly property real masterScale: !isNaN(GlobalConfig.bar.previewScale) ? GlobalConfig.bar.previewScale : 1.0
    readonly property real elementOffset: GlobalConfig.bar.perElementPreviewScale ? (!isNaN(GlobalConfig.bar.previewScales.notifications) ? GlobalConfig.bar.previewScales.notifications : 0.0) : 0.0
    readonly property real barScaleOffset: GlobalConfig.bar.previewScaleWithBar ? (!isNaN(GlobalConfig.bar.scale) ? GlobalConfig.bar.scale : 1.0) : 1.0
    readonly property real scaleOffset: Math.max(0.1, (masterScale + elementOffset) * barScaleOffset)
    readonly property real elementFontOffset: GlobalConfig.bar.perElementFontScale ? (!isNaN(GlobalConfig.bar.previewFontScales.notifications) ? GlobalConfig.bar.previewFontScales.notifications : 0.0) : 0.0
    readonly property real fontScale: Math.max(0.1, scaleOffset + (!isNaN(GlobalConfig.bar.fontScaleOffset) ? GlobalConfig.bar.fontScaleOffset : 0.0) + elementFontOffset)

    width: Math.max(300 * scaleOffset, _isSidebarOpen ? (Tokens.sizes.sidebar.width * scaleOffset) - Tokens.padding.extraLargeIncreased : 0)
    implicitWidth: width
    spacing: Tokens.spacing.small * scaleOffset

    readonly property var appSummaryList: {
        const appsMap = new Map();
        const active = (Notifs.list || []).filter(n => n && !n.closed);
        for (const n of active) {
            const name = n.appName || qsTr("System");
            const icon = n.appIcon || "notifications";
            if (!appsMap.has(name)) {
                appsMap.set(name, { name: name, icon: icon, count: 0 });
            }
            appsMap.get(name).count++;
        }
        return Array.from(appsMap.values());
    }

    // Header Row with Title and Total Count Badge
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium * root.scaleOffset
        Layout.leftMargin: Tokens.padding.small * root.scaleOffset
        Layout.rightMargin: Tokens.padding.small * root.scaleOffset
        spacing: Tokens.spacing.small * root.scaleOffset

        StyledText {
            text: qsTr("Notifications")
            font: Tokens.font.title.small.size(Tokens.font.title.small.pointSize * root.fontScale).build()
            color: Colours.palette.m3onSurface
        }

        Item { Layout.fillWidth: true }

        // Total Count Pill Badge
        StyledRect {
            visible: Notifs.openCount > 0
            implicitHeight: 22 * root.scaleOffset
            implicitWidth: countText.implicitWidth + 14 * root.scaleOffset
            radius: 11 * root.scaleOffset
            color: Colours.palette.m3primaryContainer

            StyledText {
                id: countText
                anchors.centerIn: parent
                text: qsTr("%1 total").arg(Notifs.openCount)
                font: Tokens.font.label.small.size(Tokens.font.label.small.pointSize * root.fontScale).weight(Font.Bold).build()
                color: Colours.palette.m3onPrimaryContainer
            }
        }
    }

    // App List Card
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

            // Empty State
            RowLayout {
                visible: root.appSummaryList.length === 0
                Layout.fillWidth: true
                spacing: Tokens.spacing.small * root.scaleOffset

                MaterialIcon {
                    text: "notifications_none"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.small.size(18 * root.scaleOffset).build()
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: qsTr("No notifications")
                    font: Tokens.font.body.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).build()
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // List of Apps with Notifications
            Repeater {
                model: root.appSummaryList

                delegate: RowLayout {
                    id: appRow
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small * root.scaleOffset

                    Item {
                        implicitWidth: 22 * root.scaleOffset
                        implicitHeight: 22 * root.scaleOffset
                        Layout.alignment: Qt.AlignVCenter

                        CachingImage {
                            anchors.fill: parent
                            source: Quickshell.iconPath(appRow.modelData.icon, "notifications")
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: appRow.modelData.name
                        font: Tokens.font.body.medium.size(Tokens.font.body.medium.pointSize * root.fontScale).weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledRect {
                        implicitHeight: 18 * root.scaleOffset
                        implicitWidth: appCountText.implicitWidth + 10 * root.scaleOffset
                        radius: 9 * root.scaleOffset
                        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                        Layout.alignment: Qt.AlignVCenter

                        StyledText {
                            id: appCountText
                            anchors.centerIn: parent
                            text: String(appRow.modelData.count)
                            font: Tokens.font.label.small.size(Tokens.font.label.small.pointSize * root.fontScale * 0.9).weight(Font.Bold).build()
                            color: Colours.palette.m3primary
                        }
                    }
                }
            }
        }
    }

    // Clear All Button (Visible when notifications exist)
    IconTextButton {
        visible: Notifs.openCount > 0
        Layout.fillWidth: true
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.small * root.scaleOffset
        text: qsTr("Clear all")
        icon: "clear_all"

        onClicked: Notifs.clear()
    }
}
