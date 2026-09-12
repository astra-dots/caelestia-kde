pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
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

    implicitWidth: capsuleBg.implicitWidth
    implicitHeight: capsuleBg.implicitHeight

    StyledRect {
        id: capsuleBg
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth + (Tokens.padding.extraLarge * 2 * root.clockScale)
        implicitHeight: contentRow.implicitHeight + (Tokens.padding.large * 1.5 * root.clockScale)
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainer

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.large * root.clockScale

            // Time section
            RowLayout {
                spacing: Tokens.spacing.extraSmall * root.clockScale

                StyledText {
                    text: Time.hourStr
                    font: Tokens.font.clock.size(Math.max(32, Tokens.font.headline.large.pointSize) * 1.8 * root.clockScale).weight(Font.Bold).family(root.clockFont).build()
                    color: root.safePrimary
                }

                StyledText {
                    text: ":"
                    font: Tokens.font.clock.size(Math.max(32, Tokens.font.headline.large.pointSize) * 1.8 * root.clockScale).weight(Font.Light).family(root.clockFont).build()
                    color: root.safeTertiary
                    opacity: 0.8
                }

                StyledText {
                    text: Time.minuteStr
                    font: Tokens.font.clock.size(Math.max(32, Tokens.font.headline.large.pointSize) * 1.8 * root.clockScale).weight(Font.Bold).family(root.clockFont).build()
                    color: root.safePrimary
                }

                StyledText {
                    text: Time.amPmStr
                    visible: GlobalConfig.services.useTwelveHourClock
                    font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * root.clockScale).weight(Font.Bold).family(root.sansFont).build()
                    color: root.safeSecondary
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4 * root.clockScale
                }
            }

            // Divider Pill
            Rectangle {
                Layout.preferredWidth: 3 * root.clockScale
                Layout.preferredHeight: 32 * root.clockScale
                radius: 1.5 * root.clockScale
                color: Colours.palette.m3outlineVariant
            }

            // Date & Info section
            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    text: Time.format("dddd")
                    font: Tokens.font.clock.size(Math.max(14, Tokens.font.body.medium.pointSize) * root.clockScale).weight(Font.Bold).family(root.sansFont).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: Time.format("MMMM dd, yyyy")
                    font: Tokens.font.clock.size(Math.max(12, Tokens.font.body.small.pointSize) * root.clockScale).family(root.sansFont).build()
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
