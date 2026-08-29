pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string text: ""
    property color color: Colours.palette.m3onSurface
    property font font: Tokens.font.body.small
    property int horizontalAlignment: Text.AlignLeft
    property bool animate: false
    property real speed: 32 // px per second
    property int pauseDelay: 1600 // ms
    property bool scrollEnabled: true
    property bool externalHovered: false

    readonly property bool isHovered: hoverHandler.hovered || root.externalHovered
    readonly property real textWidth: Math.max(textMeasurer.width, mainText.implicitWidth)
    readonly property real textHeight: Math.max(textMeasurer.height, mainText.implicitHeight, 18)
    readonly property bool isOverflowing: textWidth > root.width && root.width > 0
    readonly property real loopDistance: textWidth + 48

    implicitWidth: textWidth
    implicitHeight: textHeight
    height: implicitHeight
    Layout.fillWidth: true
    Layout.preferredHeight: textHeight
    clip: true

    HoverHandler {
        id: hoverHandler
    }

    TextMetrics {
        id: textMeasurer
        text: root.text
        font: root.font
    }

    Item {
        id: scrollContainer

        x: {
            if (!root.isOverflowing) {
                if (root.horizontalAlignment === Text.AlignHCenter)
                    return Math.round((root.width - root.textWidth) / 2);
                if (root.horizontalAlignment === Text.AlignRight)
                    return Math.round(root.width - root.textWidth);
                return 0;
            }
            return -animator.scrollOffset;
        }
        y: 0
        width: root.isOverflowing ? root.loopDistance * 2 : root.width
        height: root.height

        StyledText {
            id: mainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.color
            font: root.font
            animate: root.animate
        }

        StyledText {
            id: dupText
            anchors.left: parent.left
            anchors.leftMargin: root.loopDistance
            anchors.verticalCenter: parent.verticalCenter
            visible: root.isOverflowing
            text: root.text
            color: root.color
            font: root.font
            animate: false
        }
    }

    QtObject {
        id: animator
        property real scrollOffset: 0

        readonly property bool shouldScroll: root.scrollEnabled && root.isOverflowing && (root.isHovered || (Players.active?.isPlaying ?? false))

        SequentialAnimation on scrollOffset {
            id: marqueeAnim
            running: animator.shouldScroll
            loops: Animation.Infinite

            PauseAnimation {
                duration: root.pauseDelay
            }

            NumberAnimation {
                from: 0
                to: root.loopDistance
                duration: Math.max(800, (root.loopDistance / root.speed) * 1000)
                easing.type: Easing.Linear
            }
        }

        onShouldScrollChanged: {
            if (!shouldScroll) {
                marqueeAnim.stop();
                scrollOffset = 0;
            } else {
                marqueeAnim.restart();
            }
        }
    }

    onTextChanged: {
        animator.scrollOffset = 0;
    }
}
