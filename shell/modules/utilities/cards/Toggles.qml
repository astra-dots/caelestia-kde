pragma ComponentBehavior: Bound

import "../../background"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts

    property bool editMode: false
    property int draggedIndex: -1
    property var visualOrder: []

    readonly property var quickToggles: {
        const configToggles = Config.utilities.quickToggles || [];
        const disabledIds = new Set(configToggles.filter(t => t.enabled === false).map(t => t.id));

        const builtIn = [
            { id: "restartShell" },
            { id: "badapple" },
            { id: "pauseWallpaper" },
            { id: "nightlight" }
        ].filter(t => !disabledIds.has(t.id));

        const allToggles = [...configToggles.filter(t => !disabledIds.has(t.id)), ...builtIn];
        const seenIds = new Set();

        return allToggles.filter(item => {
            if (seenIds.has(item.id))
                return false;
            seenIds.add(item.id);

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false);
            }

            return true;
        });
    }

    function resetVisualOrder(): void {
        if (!root.quickToggles) {
            root.visualOrder = [];
            return;
        }
        root.visualOrder = root.quickToggles.map((_, i) => i);
    }

    onQuickTogglesChanged: {
        if (root.draggedIndex === -1) {
            root.resetVisualOrder();
        }
    }

    Component.onCompleted: root.resetVisualOrder()

    // Commit visualOrder to GlobalConfig while strictly preserving disabled toggles
    function commitVisualOrder(): void {
        if (!root.visualOrder || root.visualOrder.length !== root.quickToggles.length) return;

        const allExisting = JSON.parse(JSON.stringify(GlobalConfig.utilities.quickToggles || []));
        const disabledToggles = allExisting.filter(t => t.enabled === false);

        const activeReordered = root.visualOrder.map(i => root.quickToggles[i]?.id).filter(Boolean);
        const newToggles = activeReordered.map(id => ({ id: id, enabled: true }));

        for (const dt of disabledToggles) {
            if (!newToggles.some(nt => nt.id === dt.id)) {
                newToggles.push(dt);
            }
        }

        GlobalConfig.utilities.quickToggles = newToggles;
    }

    function getToggleIcon(id: string): string {
        switch (id) {
            case "wifi": return "wifi";
            case "bluetooth": return "bluetooth";
            case "mic": return "mic";
            case "settings": return "settings";
            case "colorpicker": return "colorize";
            case "dnd": return "notifications_off";
            case "vpn": return "vpn_key";
            case "badapple": return "nutrition";
            case "wallpaper": return "wallpaper";
            case "restartShell": return "restart_alt";
            case "pauseWallpaper": return "pause";
            case "nightlight": return "bedtime";
            default: return "tune";
        }
    }

    function getToggleChecked(id: string): bool {
        switch (id) {
            case "wifi": return Nmcli.wifiEnabled;
            case "bluetooth": return Bluetooth.defaultAdapter?.enabled ?? false;
            case "mic": return !Audio.sourceMuted;
            case "dnd": return Notifs.dnd;
            case "vpn": return VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error";
            case "pauseWallpaper": return GlobalConfig.background.videoWallpaperPaused;
            case "nightlight": return HyprSunset.active;
            default: return false;
        }
    }

    function getToggleIsToggle(id: string): bool {
        switch (id) {
            case "settings":
            case "colorpicker":
            case "badapple":
            case "wallpaper":
            case "restartShell":
                return false;
            default:
                return true;
        }
    }

    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Timer {
        id: execTimer

        interval: 250
        repeat: false

        property var pendingAction: null
        onTriggered: {
            if (pendingAction) pendingAction();
            pendingAction = null;
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // Header with Edit Mode Button
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Quick Toggles")
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurface
            }

            Item {
                Layout.fillWidth: true
            }

            // Edit Mode Button
            StyledRect {
                implicitHeight: 26
                implicitWidth: editToggleRow.implicitWidth + 14
                radius: 13
                color: root.editMode ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                StateLayer {
                    radius: 13
                    onClicked: {
                        root.editMode = !root.editMode;
                        root.draggedIndex = -1;
                        root.resetVisualOrder();
                    }
                }

                RowLayout {
                    id: editToggleRow
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: root.editMode ? "check" : "edit"
                        fontStyle: Tokens.font.icon.builders.small.size(15).build()
                        color: root.editMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: root.editMode ? qsTr("Done") : qsTr("Edit")
                        font: Tokens.font.label.small
                        color: root.editMode ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        // NORMAL MODE: Standard Native ButtonRows
        ColumnLayout {
            visible: !root.editMode
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            QuickToggleRow {
                id: row1
                model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
            }

            QuickToggleRow {
                id: row2
                visible: root.needExtraRow
                model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
            }
        }

        // EDIT MODE: Continuous Live Sliding Physics with Identical Shape-Morphing Button Style
        Item {
            id: editContainer
            visible: root.editMode
            Layout.fillWidth: true

            readonly property real rowHeight: 40
            readonly property real itemSpacing: Tokens.spacing.small
            readonly property int count1: root.splitIndex
            readonly property int count2: root.quickToggles.length - root.splitIndex

            readonly property real width1: (editContainer.width - Math.max(0, count1 - 1) * itemSpacing) / Math.max(1, count1)
            readonly property real width2: (editContainer.width - Math.max(0, count2 - 1) * itemSpacing) / Math.max(1, count2)

            implicitHeight: (root.needExtraRow ? (rowHeight * 2 + itemSpacing) : rowHeight)

            Repeater {
                id: editRepeater
                model: root.quickToggles

                delegate: StyledRect {
                    id: tile

                    required property var modelData
                    required property int index

                    readonly property int visualSlot: (root.visualOrder && root.visualOrder.indexOf(tile.index) !== -1)
                        ? root.visualOrder.indexOf(tile.index)
                        : tile.index

                    readonly property bool isRow2: root.needExtraRow && (tile.visualSlot >= root.splitIndex)
                    readonly property int col: isRow2 ? (tile.visualSlot - root.splitIndex) : tile.visualSlot

                    readonly property real currentWidth: isRow2 ? editContainer.width2 : editContainer.width1

                    readonly property real slotX: isRow2
                        ? tile.col * (editContainer.width2 + editContainer.itemSpacing)
                        : tile.col * (editContainer.width1 + editContainer.itemSpacing)

                    readonly property real slotY: isRow2
                        ? (editContainer.rowHeight + editContainer.itemSpacing)
                        : 0

                    readonly property bool isDragging: root.draggedIndex === tile.index
                    property real dragCurrentX: slotX
                    property real dragCurrentY: slotY
                    property real pressStartX: 0
                    property real pressStartY: 0

                    width: isDragging ? editContainer.width1 : currentWidth
                    height: editContainer.rowHeight
                    radius: 20

                    x: isDragging ? dragCurrentX : slotX
                    y: isDragging ? dragCurrentY : slotY
                    z: isDragging ? 100 : 1

                    scale: isDragging ? 1.08 : 1.0

                    // Live Smooth Sliding Animation for All Non-Dragging Toggles (Exactly like Pinned Apps!)
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

                    Behavior on width {
                        enabled: !tile.isDragging
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 120 }
                    }

                    readonly property bool isChecked: root.getToggleChecked(tile.modelData.id)
                    readonly property bool isToggleType: root.getToggleIsToggle(tile.modelData.id)

                    color: isDragging
                        ? Colours.layer(Colours.palette.m3primaryContainer, 2)
                        : (tile.isChecked && tile.isToggleType
                            ? Colours.palette.m3primary
                            : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2))

                    border.color: isDragging
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outlineVariant
                    border.width: isDragging ? 2 : 1

                    Elevation {
                        visible: tile.isDragging
                        anchors.fill: parent
                        radius: parent.radius
                        level: 4
                        z: -1
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.getToggleIcon(tile.modelData.id)
                        color: tile.isDragging
                            ? Colours.palette.m3onPrimaryContainer
                            : ((tile.isChecked && tile.isToggleType)
                                ? Colours.palette.m3onPrimary
                                : Colours.palette.m3onSurfaceVariant)
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        id: tileMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: tile.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                        onPressed: mouse => {
                            root.draggedIndex = tile.index;
                            tile.pressStartX = mouse.x;
                            tile.pressStartY = mouse.y;
                            tile.dragCurrentX = tile.slotX;
                            tile.dragCurrentY = tile.slotY;
                        }

                        onPositionChanged: mouse => {
                            if (root.draggedIndex === tile.index) {
                                tile.dragCurrentX += (mouse.x - tile.pressStartX);
                                tile.dragCurrentY += (mouse.y - tile.pressStartY);

                                // Non-destructive real-time visual slot calculation
                                const centerX = tile.dragCurrentX + tile.width / 2;
                                const centerY = tile.dragCurrentY + tile.height / 2;

                                const isTargetRow2 = root.needExtraRow && (centerY > editContainer.rowHeight + editContainer.itemSpacing / 2);
                                const targetColW = isTargetRow2 ? editContainer.width2 : editContainer.width1;
                                const targetCount = isTargetRow2 ? editContainer.count2 : editContainer.count1;

                                const colIdx = Math.max(0, Math.min(targetCount - 1, Math.floor(centerX / (targetColW + editContainer.itemSpacing / 2))));
                                const targetSlot = isTargetRow2 ? (root.splitIndex + colIdx) : colIdx;

                                const curSlot = root.visualOrder.indexOf(tile.index);
                                if (curSlot !== -1 && targetSlot !== curSlot && targetSlot >= 0 && targetSlot < root.quickToggles.length) {
                                    // Fluid live displacement without destroying active MouseArea!
                                    const newOrder = [...root.visualOrder];
                                    const [moved] = newOrder.splice(curSlot, 1);
                                    newOrder.splice(targetSlot, 0, moved);
                                    root.visualOrder = newOrder;
                                }
                            }
                        }

                        onReleased: mouse => {
                            if (root.draggedIndex === tile.index) {
                                root.draggedIndex = -1;
                                root.commitVisualOrder();
                            }
                        }
                    }
                }
            }
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.visibilities.utilities = false;
                            execTimer.pendingAction = () => WindowFactory.create();
                            execTimer.restart();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "colorpicker"
                    delegate: Toggle {
                        icon: "colorize"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.visibilities.utilities = false;
                            execTimer.pendingAction = () => ColorPicker.pickColor();
                            execTimer.restart();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "badapple"
                    delegate: Toggle {
                        icon: "nutrition"
                        isToggle: false
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: {
                            if (BadApplePlayer.shouldPlay)
                                BadApplePlayer.stop();
                            else
                                BadApplePlayer.play();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "wallpaper"
                    delegate: Toggle {
                        icon: "wallpaper"
                        isToggle: false
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: {
                            Visibilities.launcherInitialSearch = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
                            const visibilities = Visibilities.getForActive();
                            visibilities.launcher = true;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "restartShell"
                    delegate: Toggle {
                        icon: "restart_alt"
                        isToggle: false
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "nohup bash \"${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia/scripts/restart_shell.sh\" >/dev/null 2>&1 & disown"]);
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "pauseWallpaper"
                    delegate: Toggle {
                        id: pauseWallpaperToggle

                        icon: "pause"
                        isToggle: true

                        Component.onCompleted: checked = Qt.binding(() => GlobalConfig.background.videoWallpaperPaused)
                        onClicked: {
                            const newVal = !GlobalConfig.background.videoWallpaperPaused;
                            GlobalConfig.background.videoWallpaperPaused = newVal;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "nightlight"
                    delegate: Toggle {
                        icon: "bedtime"
                        checked: HyprSunset.active
                        onClicked: {
                            HyprSunset.toggleNightLight();
                        }
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true
    }
}
