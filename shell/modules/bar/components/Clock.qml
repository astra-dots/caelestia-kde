pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3secondary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * 1.1)
    readonly property int barThickness: Math.round(Tokens.sizes.bar.innerWidth * Math.max(0.6, !isNaN(Config.bar.scale) ? Config.bar.scale : 1.0))

    readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"
    property var bar: null
    readonly property bool isHovered: hoverHandler.hovered

    HoverHandler {
        id: hoverHandler
    }

    implicitWidth: isHorizontal ? (horizontalLayout.implicitWidth + root.padding * 2) : barThickness
    implicitHeight: isHorizontal ? barThickness : (verticalLayout.implicitHeight + root.padding * 2)

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    RowLayout {
        id: horizontalLayout

        anchors.centerIn: parent
        visible: isHorizontal
        spacing: Tokens.spacing.extraSmall

        // Time Container (Always Visible & Stationary - No Sideways Expansion)
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.hourStr
            font: root.font.build()
            color: root.colour
            renderType: Text.QtRendering
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            font: root.font.build()
            color: root.colour
            renderType: Text.QtRendering
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.minuteStr
            font: root.font.build()
            color: root.colour
            renderType: Text.QtRendering
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * 0.9).build()
                color: root.colour
                renderType: Text.QtRendering
            }
        }
    }

    ColumnLayout {
        id: verticalLayout

        anchors.centerIn: parent
        visible: !isHorizontal
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            font: {
                const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / hourMetrics.width);
                return root.font.letterSpacing(scale).build();
            }
            color: root.colour
            renderType: Text.QtRendering

            TextMetrics {
                id: hourMetrics

                font: root.font.build()
                text: Time.hourStr
            }
        }

        StyledText {
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            font: {
                const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / minMetrics.width);
                return root.font.letterSpacing(scale).build();
            }
            color: root.colour
            renderType: Text.QtRendering

            TextMetrics {
                id: minMetrics

                font: root.font.build()
                text: Time.minuteStr
            }
        }

        Loader {
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * 0.9).build()
                color: root.colour
                renderType: Text.QtRendering
            }
        }
    }
}
