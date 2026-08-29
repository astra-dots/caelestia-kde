pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property real clockScale
    required property color safePrimary
    required property color safeSecondary
    required property color safeTertiary
    required property string clockFont
    required property string sansFont

    readonly property real dialSize: 200 * root.clockScale
    implicitWidth: dialSize + (40 * root.clockScale)
    implicitHeight: dialSize + datePill.implicitHeight + (Tokens.spacing.small * 2 * root.clockScale)

    readonly property real minuteProgress: (Time.date.getMinutes() + Time.date.getSeconds() / 60.0) / 60.0

    Item {
        id: dial
        width: root.dialSize
        height: root.dialSize
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        // Outer progress arc for minute sweep
        CircularProgress {
            anchors.fill: parent
            strokeWidth: 4 * root.clockScale
            fgColour: root.safePrimary
            bgColour: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
            value: root.minuteProgress
            startAngle: -90
            sweepAngle: 360
        }

        // Center Digital Display
        ColumnLayout {
            anchors.centerIn: parent
            spacing: -Tokens.spacing.small * root.clockScale

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2 * root.clockScale

                StyledText {
                    text: Time.hourStr
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 1.5 * root.clockScale).weight(Font.ExtraBold).family(root.clockFont).build()
                    color: root.safePrimary
                }

                StyledText {
                    text: ":"
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 1.5 * root.clockScale).weight(Font.Light).family(root.clockFont).build()
                    color: root.safeTertiary
                }

                StyledText {
                    text: Time.minuteStr
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 1.5 * root.clockScale).weight(Font.Bold).family(root.clockFont).build()
                    color: root.safeSecondary
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("dddd")
                font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * 0.95 * root.clockScale).weight(Font.Medium).family(root.sansFont).build()
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // Date Pill Badge Underneath
    StyledRect {
        id: datePill
        anchors.top: dial.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small * root.clockScale
        implicitHeight: dateText.implicitHeight + (8 * root.clockScale)
        implicitWidth: dateText.implicitWidth + (20 * root.clockScale)
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledText {
            id: dateText
            anchors.centerIn: parent
            text: Time.format("MMM dd, yyyy").toUpperCase()
            font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * root.clockScale).weight(Font.Bold).family(root.sansFont).letterSpacing(1).build()
            color: Colours.palette.m3primary
        }
    }
}
