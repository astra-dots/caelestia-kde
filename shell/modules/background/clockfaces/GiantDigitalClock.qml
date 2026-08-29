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

    implicitWidth: layout.implicitWidth + (Tokens.padding.large * 2 * root.clockScale)
    implicitHeight: layout.implicitHeight + (Tokens.padding.medium * 2 * root.clockScale)

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: -Tokens.spacing.small * 3 * root.clockScale

        // Hour Numeral (Top Row)
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 4.2 * root.clockScale).weight(Font.ExtraBold).family(root.clockFont).build()
            color: root.safePrimary
        }

        // Minute Numeral (Bottom Row)
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 4.2 * root.clockScale).weight(Font.ExtraBold).family(root.clockFont).build()
            color: root.safeSecondary
        }

        // Date & Weather Status Pill
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium * root.clockScale
            implicitHeight: infoRow.implicitHeight + (10 * root.clockScale)
            implicitWidth: infoRow.implicitWidth + (24 * root.clockScale)
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainerHigh

            RowLayout {
                id: infoRow
                anchors.centerIn: parent
                spacing: Tokens.spacing.small * root.clockScale

                StyledText {
                    text: Time.format("ddd, MMM dd")
                    font: Tokens.font.clock.size(Tokens.font.body.medium.pointSize * root.clockScale).weight(Font.Medium).family(root.sansFont).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: "•"
                    font: Tokens.font.clock.size(Tokens.font.body.medium.pointSize * root.clockScale).family(root.sansFont).build()
                    color: root.safeTertiary
                    visible: (Weather.data?.temp ?? "") !== ""
                }

                StyledText {
                    text: (Weather.data?.temp ?? "") !== "" ? `${Math.round(Weather.data.temp)}°C` : ""
                    font: Tokens.font.clock.size(Tokens.font.body.medium.pointSize * root.clockScale).weight(Font.Bold).family(root.sansFont).build()
                    color: root.safePrimary
                    visible: (Weather.data?.temp ?? "") !== ""
                }
            }
        }
    }
}
