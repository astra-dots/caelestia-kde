pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    property var parentList: null
    property DrawerVisibilities visibilities: null

    readonly property list<DesktopEntry> pinnedApps: LauncherPins.pinnedEntries
    property bool editMode: false
    property int draggedIndex: -1
    property var visualOrder: []

    function resetVisualOrder(): void {
        if (!root.pinnedApps) {
            root.visualOrder = [];
            return;
        }
        root.visualOrder = root.pinnedApps.map((_, i) => i);
    }

    onPinnedAppsChanged: {
        if (root.draggedIndex === -1) {
            root.resetVisualOrder();
        }
    }

    Component.onCompleted: root.resetVisualOrder()

    property int currentIndex: 0

    readonly property var currentModelData: {
        if (!root.pinnedApps || root.pinnedApps.length === 0) return null;
        const targetIdx = (root.visualOrder && root.visualOrder.length > root.currentIndex)
            ? root.visualOrder[root.currentIndex]
            : root.currentIndex;
        return root.pinnedApps[targetIdx] ?? root.pinnedApps[0] ?? null;
    }

    readonly property var currentItem: ({
        modelData: root.currentModelData,
        clicked: () => root.launchCurrent(),
        onClicked: () => root.launchCurrent()
    })

    function launchCurrent(): void {
        if (root.currentModelData) {
            Apps.launch(root.currentModelData);
            if (root.visibilities)
                root.visibilities.launcher = false;
        }
    }

    function incrementCurrentIndex(): void {
        if (root.pinnedApps.length > 0)
            root.currentIndex = (root.currentIndex + 2 < root.pinnedApps.length) ? (root.currentIndex + 2) : Math.min(root.pinnedApps.length - 1, root.currentIndex + 1);
    }

    function decrementCurrentIndex(): void {
        if (root.pinnedApps.length > 0)
            root.currentIndex = (root.currentIndex - 2 >= 0) ? (root.currentIndex - 2) : Math.max(0, root.currentIndex - 1);
    }

    function moveLeft(): void {
        if (root.pinnedApps.length > 0)
            root.currentIndex = Math.max(0, root.currentIndex - 1);
    }

    function moveRight(): void {
        if (root.pinnedApps.length > 0)
            root.currentIndex = Math.min(root.pinnedApps.length - 1, root.currentIndex + 1);
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: Math.max(160, layout.implicitHeight)

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Pinned")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
                renderType: Text.QtRendering
            }

            // Edit Mode Toggle Button
            StyledRect {
                visible: root.pinnedApps.length > 0
                implicitHeight: 28
                implicitWidth: editRow.implicitWidth + 16
                radius: 14
                color: root.editMode ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    radius: 14
                    onClicked: {
                        root.editMode = !root.editMode;
                        root.draggedIndex = -1;
                        root.resetVisualOrder();
                    }
                }

                RowLayout {
                    id: editRow
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: root.editMode ? "check" : "edit"
                        fontStyle: Tokens.font.icon.builders.small.size(16).build()
                        color: root.editMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: root.editMode ? qsTr("Done") : qsTr("Edit")
                        font: Tokens.font.label.small
                        color: root.editMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            IconTextButton {
                text: qsTr("All apps")
                icon: "apps"
                type: TextButton.Tonal
                onClicked: {
                    if (root.parentList)
                        root.parentList.showAllApps = true;
                }
            }
        }

        // Empty State
        Item {
            visible: root.pinnedApps.length === 0
            Layout.fillWidth: true
            implicitHeight: 180

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    Layout.alignment: Qt.AlignHCenter

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "push_pin"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.builders.medium.size(24).build()
                    }
                }

                StyledText {
                    text: qsTr("No Pinned Apps")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.QtRendering
                }

                StyledText {
                    text: qsTr("Pin apps from the All Apps list using the push pin icon")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.QtRendering
                }

                IconTextButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: qsTr("Browse All Apps")
                    icon: "apps"
                    type: TextButton.Tonal
                    onClicked: {
                        if (root.parentList)
                            root.parentList.showAllApps = true;
                    }
                }
            }
        }

        // Android Homescreen-style Continuous Live Drag & Reorder Grid
        Item {
            id: gridContainer

            visible: root.pinnedApps.length > 0
            Layout.fillWidth: true
            implicitHeight: Math.ceil(root.pinnedApps.length / 2) * (64 + Tokens.spacing.medium)

            readonly property real colWidth: (gridContainer.width - Tokens.spacing.medium) / 2
            readonly property real rowHeight: 64
            readonly property real spacing: Tokens.spacing.medium

            Repeater {
                id: gridRepeater
                model: root.pinnedApps

                delegate: StyledRect {
                    id: tile

                    required property var modelData
                    required property int index

                    // Calculate live visual slot position based on non-destructive visualOrder
                    readonly property int visualSlot: (root.visualOrder && root.visualOrder.indexOf(tile.index) !== -1)
                        ? root.visualOrder.indexOf(tile.index)
                        : tile.index

                    readonly property int col: tile.visualSlot % 2
                    readonly property int row: Math.floor(tile.visualSlot / 2)

                    readonly property real slotX: tile.col * (gridContainer.colWidth + gridContainer.spacing)
                    readonly property real slotY: tile.row * (gridContainer.rowHeight + gridContainer.spacing)

                    readonly property bool isDragging: root.draggedIndex === tile.index
                    property real dragCurrentX: slotX
                    property real dragCurrentY: slotY
                    property real pressStartX: 0
                    property real pressStartY: 0

                    width: gridContainer.colWidth
                    height: gridContainer.rowHeight
                    radius: Tokens.rounding.large

                    x: isDragging ? dragCurrentX : slotX
                    y: isDragging ? dragCurrentY : slotY
                    z: isDragging ? 100 : 1

                    scale: isDragging ? 1.05 : 1.0

                    // Live Smooth Sliding Animation for All Non-Dragging Tiles
                    Behavior on x {
                        enabled: !tile.isDragging
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on y {
                        enabled: !tile.isDragging
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 120 }
                    }

                    readonly property bool isSelected: root.currentIndex === tile.visualSlot

                    color: isDragging
                        ? Colours.layer(Colours.palette.m3primaryContainer, 2)
                        : ((tile.isSelected || tileMouse.containsMouse || root.editMode)
                            ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) 
                            : Colours.layer(Colours.palette.m3surfaceContainerLow, 1))

                    border.color: isDragging
                        ? Colours.palette.m3primary
                        : (root.editMode ? Colours.palette.m3outlineVariant : "transparent")
                    border.width: (isDragging || root.editMode) ? 1.5 : 0

                    Elevation {
                        visible: tile.isDragging
                        anchors.fill: parent
                        radius: parent.radius
                        level: 4
                        z: -1
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        Item {
                            implicitWidth: 38
                            implicitHeight: 38
                            Layout.alignment: Qt.AlignVCenter

                            CachingImage {
                                anchors.fill: parent
                                source: Quickshell.iconPath(tile.modelData?.icon, "image-missing")
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: tile.modelData?.name ?? ""
                            font: Tokens.font.label.builders.medium.scale(0.93).weight(Font.Medium).build()
                            color: tile.isDragging ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            renderType: Text.QtRendering
                        }

                        // Direct Unpin Button in Edit Mode
                        IconButton {
                            visible: root.editMode
                            icon: "close"
                            type: IconButton.Tonal
                            padding: 2
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: {
                                if (tile.modelData?.id)
                                    LauncherPins.unpin(tile.modelData.id);
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: root.editMode ? (tile.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor

                        onPressed: mouse => {
                            root.currentIndex = tile.index;
                            if (root.editMode) {
                                root.draggedIndex = tile.index;
                                tile.pressStartX = mouse.x;
                                tile.pressStartY = mouse.y;
                                tile.dragCurrentX = tile.slotX;
                                tile.dragCurrentY = tile.slotY;
                            }
                        }

                        onPositionChanged: mouse => {
                            if (root.editMode && root.draggedIndex === tile.index) {
                                tile.dragCurrentX += (mouse.x - tile.pressStartX);
                                tile.dragCurrentY += (mouse.y - tile.pressStartY);

                                // Non-destructive real-time visual slot displacement
                                const centerX = tile.dragCurrentX + tile.width / 2;
                                const centerY = tile.dragCurrentY + tile.height / 2;

                                const colIdx = Math.max(0, Math.min(1, Math.floor(centerX / (gridContainer.colWidth + gridContainer.spacing / 2))));
                                const rowIdx = Math.max(0, Math.floor(centerY / (gridContainer.rowHeight + gridContainer.spacing / 2)));
                                const targetSlot = Math.max(0, Math.min(root.pinnedApps.length - 1, rowIdx * 2 + colIdx));

                                const curSlot = root.visualOrder.indexOf(tile.index);
                                if (curSlot !== -1 && targetSlot !== curSlot) {
                                    // Fluid live displacement without destroying active MouseArea!
                                    const newOrder = [...root.visualOrder];
                                    const [moved] = newOrder.splice(curSlot, 1);
                                    newOrder.splice(targetSlot, 0, moved);
                                    root.visualOrder = newOrder;
                                }
                            }
                        }

                        onReleased: mouse => {
                            if (root.editMode && root.draggedIndex === tile.index) {
                                root.draggedIndex = -1;
                                // Commit final persistent order to launcher_pinned.json
                                if (root.visualOrder && root.visualOrder.length === root.pinnedApps.length) {
                                    const finalAppIds = root.visualOrder.map(i => root.pinnedApps[i]?.id).filter(Boolean);
                                    LauncherPins.setPins(finalAppIds);
                                }
                            }
                        }

                        onClicked: mouse => {
                            if (root.editMode) return;
                            root.currentIndex = tile.index;
                            Apps.launch(tile.modelData);
                            if (root.visibilities)
                                root.visibilities.launcher = false;
                        }
                    }
                }
            }
        }
    }
}
