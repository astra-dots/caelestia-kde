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

    implicitWidth: layout.implicitWidth + (Tokens.padding.large * 4 * root.clockScale)
    implicitHeight: layout.implicitHeight + (Tokens.padding.extraLargeIncreased * root.clockScale)

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Tokens.spacing.large * root.clockScale

        RowLayout {
            spacing: Tokens.spacing.small

            StyledText {
                text: Time.hourStr
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).weight(Font.Bold).family(root.clockFont).build()
                color: root.safePrimary
            }

            StyledText {
                text: ":"
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).family(root.clockFont).build()
                color: root.safeTertiary
                opacity: 0.8
                Layout.topMargin: -Tokens.padding.large * 1.5 * root.clockScale
            }

            StyledText {
                text: Time.minuteStr
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).weight(Font.Bold).family(root.clockFont).build()
                color: root.safeSecondary
            }

            Loader {
                asynchronous: true
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Tokens.padding.large * 1.4 * root.clockScale

                active: GlobalConfig.services.useTwelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: Time.amPmStr
                    font: Tokens.font.clock.size(Tokens.font.title.medium.pointSize * root.clockScale).family(root.sansFont).build()
                    color: root.safeSecondary
                }
            }
        }

        StyledRect {
            Layout.fillHeight: true
            Layout.preferredWidth: 4 * root.clockScale
            Layout.topMargin: Tokens.spacing.large * root.clockScale
            Layout.bottomMargin: Tokens.spacing.large * root.clockScale
            radius: Tokens.rounding.full
            color: root.safePrimary
            opacity: 0.8
        }

        ColumnLayout {
            spacing: 0

            StyledText {
                text: Time.format("MMMM").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.title.medium.pointSize * root.clockScale).letterSpacing(4).weight(Font.Bold).family(root.sansFont).build()
                color: root.safeSecondary
            }

            StyledText {
                text: Time.format("dd")
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * root.clockScale).letterSpacing(2).weight(Font.Medium).family(root.sansFont).build()
                color: root.safePrimary
            }

            StyledText {
                text: Time.format("dddd")
                font: Tokens.font.clock.size(Tokens.font.body.large.pointSize * root.clockScale).letterSpacing(2).family(root.sansFont).build()
                color: root.safeSecondary
            }
        }
    }
}
