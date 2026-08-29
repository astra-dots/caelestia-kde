pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities

    property string vAnchor: "top"
    property string hAnchor: "center"

    readonly property alias item: content.item
    readonly property bool shouldBeActive: visibilities.screenshot
    property real offsetScale: shouldBeActive ? 0 : 1

    clip: Config.bar.position === "top"
    visible: offsetScale < 1
    anchors.topMargin: (Config.bar.position === "top" ? 0 : -implicitHeight - 5) * offsetScale
    height: Config.bar.position === "top" ? implicitHeight * (1 - offsetScale) : implicitHeight
    width: implicitWidth
    implicitHeight: 52
    implicitWidth: content.item ? content.item.implicitWidth : 620
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        active: root.shouldBeActive || root.visible
        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
