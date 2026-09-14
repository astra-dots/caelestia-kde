import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    readonly property bool active: {
        if (typeof KWinWorkspaceState !== "undefined" && KWinWorkspaceState)
            return Boolean(KWinWorkspaceState.showingDesktop);
        return false;
    }

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        id: stateLayer

        // Workaround to make the circular layer centered and larger than parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full

        stateOpacity: root.active ? (stateLayer.containsMouse ? 0.28 : 0.18) : (stateLayer.containsMouse ? 0.08 : 0)

        Accessible.name: qsTr("Show desktop")
        Accessible.role: Accessible.Button
        Accessible.description: qsTr("Minimise all windows to show the desktop")
        onClicked: Quickshell.execDetached(["qdbus6", "org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component.invokeShortcut", "Show Desktop"])
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: Centering.pixelAlign(parent.width, width)

        text: "keyboard_double_arrow_down"
        color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
        rotation: root.active ? 180 : 0

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on rotation {
            Anim { type: Anim.FastSpatial }
        }
    }
}
