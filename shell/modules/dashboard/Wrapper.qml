pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property DashboardState dashState: DashboardState {
        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }
    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: visibilities.dashboard && Config.dashboard.enabled && !visibilities.overview
    property real offsetScale: shouldBeActive ? 0 : 1

    clip: Config.bar.position === "top"
    visible: offsetScale < 1
    anchors.topMargin: (Config.bar.position === "top" ? 0 : -implicitHeight - 5) * offsetScale
    height: Config.bar.position === "top" ? implicitHeight * (1 - offsetScale) : implicitHeight
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }
    focus: root.shouldBeActive

    Keys.onLeftPressed: event => {
        const item = content.item;
        if (item && item.dashboardTabs && item.dashboardTabs.length > 1) {
            root.dashState.currentTab = (root.dashState.currentTab - 1 + item.dashboardTabs.length) % item.dashboardTabs.length;
            event.accepted = true;
        }
    }
    Keys.onRightPressed: event => {
        const item = content.item;
        if (item && item.dashboardTabs && item.dashboardTabs.length > 1) {
            root.dashState.currentTab = (root.dashState.currentTab + 1) % item.dashboardTabs.length;
            event.accepted = true;
        }
    }
    Keys.onEscapePressed: event => {
        root.visibilities.dashboard = false;
        event.accepted = true;
    }

    property bool hasBeenOpened: false

    Component.onCompleted: {
        Qt.callLater(() => {
            root.hasBeenOpened = true;
        });
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            hasBeenOpened = true;
    }

    Loader {
        id: content

        focus: root.shouldBeActive
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: root.visible
        active: root.hasBeenOpened || root.shouldBeActive || root.visible
        sourceComponent: Content {
            visibilities: root.visibilities
            dashState: root.dashState
            facePicker: root.facePicker
        }
        onLoaded: {
            if (root.shouldBeActive && item) {
                item.forceActiveFocus();
            }
        }
    }

    Connections {
        target: root
        function onShouldBeActiveChanged() {
            if (root.shouldBeActive && content.item) {
                content.item.forceActiveFocus();
            }
        }
    }
}
