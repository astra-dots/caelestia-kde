pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
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
    required property string sansFont

    readonly property real baseSize: 220 * root.clockScale
    implicitWidth: baseSize
    implicitHeight: baseSize + (datePill.visible ? datePill.height + Tokens.spacing.small * root.clockScale : 0)

    readonly property int hours: Time.date.getHours()
    readonly property int minutes: Time.date.getMinutes()
    readonly property int seconds: Time.date.getSeconds()

    // Smooth second angle with millisecond interpolation when active
    readonly property real hourAngle: ((root.hours % 12) + root.minutes / 60.0 + root.seconds / 3600.0) * 30.0
    readonly property real minuteAngle: (root.minutes + root.seconds / 60.0) * 6.0
    readonly property real secondAngle: root.seconds * 6.0

    Item {
        id: dialContainer
        width: root.baseSize
        height: root.baseSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        // Material Shape Dial (Solid M3 Background)
        MaterialShape {
            id: dialShape
            anchors.fill: parent
            shape: MaterialShape.Cookie9Sided
            color: Colours.palette.m3secondaryContainer
        }

        // Hour markers (12 subtle radial dots)
        Repeater {
            model: 12
            delegate: Item {
                id: markerHolder
                required property int index
                anchors.fill: parent
                rotation: markerHolder.index * 30

                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 16 * root.clockScale
                    width: markerHolder.index % 3 === 0 ? 6 * root.clockScale : 3.5 * root.clockScale
                    height: width
                    radius: width / 2
                    color: markerHolder.index % 3 === 0 ? root.safePrimary : Colours.palette.m3onSecondaryContainer
                    opacity: markerHolder.index % 3 === 0 ? 0.9 : 0.5
                }
            }
        }

        // Hour Hand
        Item {
            anchors.fill: parent
            rotation: root.hourAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: 400
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                width: 10 * root.clockScale
                height: dialContainer.height * 0.28
                radius: 5 * root.clockScale
                color: root.safePrimary
            }
        }

        // Minute Hand
        Item {
            anchors.fill: parent
            rotation: root.minuteAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: 300
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                width: 6 * root.clockScale
                height: dialContainer.height * 0.38
                radius: 3 * root.clockScale
                color: root.safeTertiary
            }
        }

        // Second Hand
        Item {
            anchors.fill: parent
            rotation: root.secondAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: 150
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutBack
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -12 * root.clockScale
                width: 2.5 * root.clockScale
                height: dialContainer.height * 0.44
                radius: 1.25 * root.clockScale
                color: Colours.palette.m3error
            }

            // Second counter-weight dot
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 10 * root.clockScale
                width: 6 * root.clockScale
                height: width
                radius: width / 2
                color: Colours.palette.m3error
            }
        }

        // Center Cap
        Rectangle {
            anchors.centerIn: parent
            width: 14 * root.clockScale
            height: width
            radius: width / 2
            color: Colours.palette.m3surface
            border.color: root.safePrimary
            border.width: 2.5 * root.clockScale
        }
    }

    // Date Pill Badge Underneath
    StyledRect {
        id: datePill
        anchors.top: dialContainer.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Tokens.spacing.small * root.clockScale
        implicitHeight: dateText.implicitHeight + (8 * root.clockScale)
        implicitWidth: dateText.implicitWidth + (20 * root.clockScale)
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHigh

        StyledText {
            id: dateText
            anchors.centerIn: parent
            text: Time.format("ddd, MMM dd")
            font: Tokens.font.clock.size(Tokens.font.body.medium.pointSize * root.clockScale).weight(Font.Medium).family(root.sansFont).build()
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
