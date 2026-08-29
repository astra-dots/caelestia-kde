import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

PanelWindow {
    id: root

    visible: true
    color: "transparent"
    WlrLayershell.namespace: "osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    enum SnipAction { Copy, Edit, Search, CharRecognition, Record, RecordWithSound }
    enum SelectionMode { RectCorners, Circle }
    enum Phase { Select, Post }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var phase: RegionSelection.Phase.Select
    property bool shiftHeld: false
    property int delaySeconds: 0

    signal dismiss()

    onDismiss: {
        root.snapshotWorkspaceId = 0;
        root.snapshotWorkspaceUuid = "";
        root.lastHoverFocusedAddress = "";
        root.shiftHeld = false;
    }

    property string screenshotDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/caelestia-screenshot`
    property color overlayColor: Qt.rgba(0, 0, 0, 0.45)
    property color brightText: Colours.palette.m3onSurface
    property color brightSecondary: Colours.palette.m3secondary
    property color brightTertiary: Colours.palette.m3tertiary
    property color selectionBorderColor: brightSecondary
    property color selectionFillColor: "#33ffffff"
    property color windowBorderColor: Colours.palette.m3primary
    property color windowFillColor: Qt.alpha(Colours.palette.m3primary, 0.18)
    property color imageBorderColor: brightTertiary
    property color imageFillColor: Qt.rgba(imageBorderColor.r, imageBorderColor.g, imageBorderColor.b, 0.15)
    property color onBorderColor: "#ff000000"
    property real targetRegionOpacity: 0.8
    property bool contentRegionOpacity: false

    property int snapshotWorkspaceId: 0
    property string snapshotWorkspaceUuid: ""

    readonly property var windows: {
        let arr = Array.from(KWinActiveWindowBridge.windowList || []);
        const useSnapshot = root.snapshotWorkspaceId > 0 || root.snapshotWorkspaceUuid !== "";
        const activeId = useSnapshot ? root.snapshotWorkspaceId
            : (typeof KWinWorkspaceState !== "undefined" ? KWinWorkspaceState.activeId : 0);
        const activeIdx = activeId > 0 ? activeId - 1 : 0;
        const activeUuid = useSnapshot ? root.snapshotWorkspaceUuid
            : (typeof KWinWorkspaceState !== "undefined" && KWinWorkspaceState.workspaces[activeIdx]
                ? KWinWorkspaceState.workspaces[activeIdx].id : "");

        if (activeId > 0 || activeUuid !== "") {
            arr = arr.filter(w => {
                if (!w.workspace) return true;
                if (typeof w.workspace.id === "number") {
                    if (w.workspace.id === -1) return true;
                    return w.workspace.id === activeId;
                } else if (typeof w.workspace.id === "string") {
                    if (w.workspace.id === "") return true;
                    return w.workspace.id === activeUuid;
                }
                return true;
            });
        }

        return arr.sort((a, b) => {
            if (a.floating === b.floating) return 0;
            return a.floating ? -1 : 1;
        });
    }

    readonly property var layers: ({})
    readonly property real falsePositivePreventionRatio: 0.5
    readonly property real monitorScale: (frozenImage.sourceSize.width > 0 && root.screen.width > 0) ? (frozenImage.sourceSize.width / root.screen.width) : (screen.devicePixelRatio || 1.0)
    readonly property real monitorOffsetX: screen.x || 0
    readonly property real monitorOffsetY: screen.y || 0
    property string activeWorkspaceId: ""
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}.png`

    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property var points: []
    property var mouseButton: null
    property var imageRegions: []

    readonly property var windowRegions: RegionFunctions.filterWindowRegionsByLayers(
        root.windows,
        root.layerRegions
    ).map(window => {
        return {
            at: [window.x - root.monitorOffsetX, window.y - root.monitorOffsetY],
            size: [window.width, window.height],
            class: window.class,
            title: window.title,
            address: window.address || "",
        }
    })

    readonly property var layerRegions: []

    property bool enableWindowRegions: root.phase === RegionSelection.Phase.Select && root.showWindowOutlines
    property bool enableLayerRegions: root.phase === RegionSelection.Phase.Select && false
    property bool enableContentRegions: false

    property bool showWindowOutlines: false

    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    property string targetedWindowAddress: ""
    property string lastHoverFocusedAddress: ""

    Timer {
        id: focusHoverTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (root.targetedWindowAddress && root.targetedWindowAddress !== root.lastHoverFocusedAddress) {
                root.lastHoverFocusedAddress = root.targetedWindowAddress;
                KWinActiveWindowBridge.focusWindow(root.targetedWindowAddress);
            }
        }
    }

    function targetedRegionValid(): bool {
        return targetedRegionX >= 0 && targetedRegionY >= 0 && targetedRegionWidth > 0 && targetedRegionHeight > 0
    }

    function setRegionToTargeted() {
        if (!targetedRegionValid()) return;
        root.dragStartX = root.targetedRegionX;
        root.dragStartY = root.targetedRegionY;
        root.draggingX = root.targetedRegionX + root.targetedRegionWidth;
        root.draggingY = root.targetedRegionY + root.targetedRegionHeight;
    }

    function updateTargetedRegion(mouseX, mouseY) {
        if (!root.enableWindowRegions && !root.enableLayerRegions && !root.enableContentRegions) {
            root.targetedRegionX = -1;
            root.targetedRegionY = -1;
            root.targetedRegionWidth = 0;
            root.targetedRegionHeight = 0;
            root.targetedWindowAddress = "";
            return;
        }

        let clickedWindow = RegionFunctions.findClickedRegion(
            mouseX, mouseY,
            root.enableLayerRegions ? root.layerRegions : [],
            root.enableWindowRegions ? root.windowRegions : [],
            root.enableContentRegions ? root.imageRegions : [],
            root.falsePositivePreventionRatio
        );

        if (clickedWindow !== null) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            const newAddr = clickedWindow.address || "";
            if (root.showWindowOutlines && newAddr && newAddr !== root.targetedWindowAddress) {
                root.targetedWindowAddress = newAddr;
                focusHoverTimer.restart();
            } else {
                root.targetedWindowAddress = newAddr;
            }
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
        root.targetedWindowAddress = "";
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = true;
        }
    }

    property bool preparationDone: false
    property string frozenImageSource: ""

    onPreparationDoneChanged: {
        if (!preparationDone) return;
        root.frozenImageSource = "file://" + root.screenshotPath;
        if (typeof KWinWorkspaceState !== "undefined") {
            const snapId = KWinWorkspaceState.activeId;
            root.snapshotWorkspaceId = snapId;
            const snapIdx = snapId > 0 ? snapId - 1 : 0;
            root.snapshotWorkspaceUuid = KWinWorkspaceState.workspaces[snapIdx]
                ? KWinWorkspaceState.workspaces[snapIdx].id : "";
        }
        root.visible = true;
        mouseArea.forceActiveFocus();
    }

    Component.onDestruction: {
        if (!root.screenshotConsumed) {
            Quickshell.execDetached(["rm", "-f", root.screenshotPath]);
        }
    }

    property bool screenshotConsumed: false

    function snip() {
        root.screenshotConsumed = true;
        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));

        const command = ScreenshotAction.getCommand(
            root.regionX * root.monitorScale,
            root.regionY * root.monitorScale,
            root.regionWidth * root.monitorScale,
            root.regionHeight * root.monitorScale,
            root.screenshotPath,
            ScreenshotAction.Action.Copy,
            "",
            root.shiftHeld
        );
        Quickshell.execDetached(command);
        root.dismiss();
    }

    function snipWindow(windowAddress) {
        root.screenshotConsumed = true;
        const saveDir = `${Paths.pictures}/Screenshots`;
        const tmpFile = Paths.runtimeTemp(`snip-window-${Date.now()}.png`);
        const actionCmdArray = ScreenshotAction.getCommand(
            0, 0, 99999, 99999, tmpFile, ScreenshotAction.Action.Copy, saveDir, root.shiftHeld
        );
        const actionScript = actionCmdArray[2];

        const command = [
            "bash", "-c",
            `set -euo pipefail; ` +
            `spectacle -b -a -n -o '${tmpFile}' && ${actionScript}`
        ];

        if (windowAddress) {
            KWinActiveWindowBridge.focusWindow(windowAddress);
        }
        root.dismiss();
        Qt.callLater(() => { Quickshell.execDetached(command); });
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.visible

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Shift) {
                root.shiftHeld = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.dismiss();
                event.accepted = true;
            } else if (event.key === Qt.Key_1) {
                root.showWindowOutlines = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_2) {
                root.showWindowOutlines = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_3) {
                root.regionX = 0;
                root.regionY = 0;
                root.regionWidth = root.screen.width;
                root.regionHeight = root.screen.height;
                root.snip();
                event.accepted = true;
            } else if (event.key === Qt.Key_4) {
                Quickshell.execDetached(["spectacle", "-g"]);
                root.dismiss();
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Shift) {
                root.shiftHeld = false;
                event.accepted = true;
            }
        }
    }

    Image {
        id: frozenImage
        anchors.fill: parent
        source: root.frozenImageSource
        visible: root.frozenImageSource !== ""
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        focus: root.visible
        cursorShape: root.showWindowOutlines
            ? (root.targetedRegionValid() ? Qt.PointingHandCursor : Qt.ArrowCursor)
            : (root.draggedAway ? Qt.ArrowCursor : Qt.CrossCursor)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.dismiss();
                return;
            }
            if (mouse.modifiers & Qt.ShiftModifier) root.shiftHeld = true;
            // Ignore clicks within top bar area
            if (mouse.y < pillBar.y + pillBar.height + 15 && mouse.x >= pillBar.x - 10 && mouse.x <= pillBar.x + pillBar.width + 10) {
                return;
            }

            mouse.accepted = true;
            root.mouseButton = mouse.button;
            if (root.showWindowOutlines) return;
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
        }

        onReleased: (mouse) => {
            if (mouse.modifiers & Qt.ShiftModifier) root.shiftHeld = true;
            if (root.showWindowOutlines) {
                if (root.targetedWindowAddress) {
                    root.snipWindow(root.targetedWindowAddress);
                } else if (root.targetedRegionValid()) {
                    root.setRegionToTargeted();
                    root.snip();
                }
                return;
            }

            root.dragging = false;
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                if (root.targetedRegionValid()) {
                    root.setRegionToTargeted();
                }
            }
            if (root.regionWidth > 10 && root.regionHeight > 10) {
                root.snip();
            }
        }

        onPositionChanged: (mouse) => {
            if (mouse.modifiers & Qt.ShiftModifier) root.shiftHeld = true;
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (root.showWindowOutlines || !root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
            root.points.push({ x: mouse.x, y: mouse.y });
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: !root.showWindowOutlines && root.selectionMode === RegionSelection.SelectionMode.RectCorners
            sourceComponent: RectCornersSelectionDetails {
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        // Caelestia Native Window Regions with Title, Icon & Hover Highlights
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableWindowRegions) {
                        return root.windowRegions;
                    } else {
                        return [];
                    }
                }
            }
            delegate: TargetRegion {
                z: targeted ? 99 : 2
                required property var modelData
                clientDimensions: modelData
                showIcon: true
                text: modelData.title || modelData["class"] || ""
                iconName: modelData["class"] || ""
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0]
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])
                opacity: root.draggedAway ? 0 : (root.targetedRegionValid() && !targeted ? 0 : root.targetRegionOpacity)
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : Qt.alpha(root.windowFillColor, 0)
                radius: 12
            }
        }
    }

    // ==========================================
    // TOP FLOATING MATERIAL 3 EXPRESSIVE TOOLBAR
    // ==========================================
    StyledRect {
        id: pillBar
        z: 100

        anchors {
            top: parent.top
            topMargin: 18
            horizontalCenter: parent.horizontalCenter
        }

        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
        border.color: Colours.palette.m3outlineVariant
        border.width: 1
        radius: 28

        implicitHeight: 54
        implicitWidth: contentRow.implicitWidth + 24

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            // Header Camera Icon Badge
            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: Colours.palette.m3primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "photo_camera"
                    color: Colours.palette.m3onPrimaryContainer
                    fontStyle: Tokens.font.icon.small
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 22
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 1. REGION MODE
            StyledRect {
                id: btnRegion
                implicitWidth: regionLayout.implicitWidth + 16
                implicitHeight: 36
                radius: 18
                color: !root.showWindowOutlines ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    radius: 18
                    onClicked: root.showWindowOutlines = false
                }

                RowLayout {
                    id: regionLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "crop_free"
                        color: !root.showWindowOutlines ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Region")
                        font: Tokens.font.label.medium
                        color: !root.showWindowOutlines ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Drag anywhere to snip a region & annotate in Spectacle")
                }
            }

            // 2. WINDOW HOVER MODE (Caelestia Native TargetRegion Outlines)
            StyledRect {
                id: btnWindow
                implicitWidth: winLayout.implicitWidth + 16
                implicitHeight: 36
                radius: 18
                color: root.showWindowOutlines ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    radius: 18
                    onClicked: root.showWindowOutlines = true
                }

                RowLayout {
                    id: winLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "near_me"
                        color: root.showWindowOutlines ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Window")
                        font: Tokens.font.label.medium
                        color: root.showWindowOutlines ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Hover over any window to highlight and click to capture")
                }
            }

            // 3. FULLSCREEN BUTTON
            StyledRect {
                id: btnFull
                implicitWidth: fullLayout.implicitWidth + 16
                implicitHeight: 36
                radius: 18
                color: Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    radius: 18
                    onClicked: {
                        root.regionX = 0;
                        root.regionY = 0;
                        root.regionWidth = root.screen.width;
                        root.regionHeight = root.screen.height;
                        root.snip();
                    }
                }

                RowLayout {
                    id: fullLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "fullscreen"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Full Screen")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Instant Fullscreen Capture")
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 22
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 4. OPEN SPECTACLE BUTTON
            StyledRect {
                id: btnSpectacle
                implicitWidth: specLayout.implicitWidth + 16
                implicitHeight: 36
                radius: 18
                color: Colours.palette.m3tertiaryContainer

                StateLayer {
                    radius: 18
                    onClicked: {
                        Quickshell.execDetached(["spectacle", "-g"]);
                        root.dismiss();
                    }
                }

                RowLayout {
                    id: specLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "camera"
                        color: Colours.palette.m3onTertiaryContainer
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Spectacle")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onTertiaryContainer
                    }
                }

                Tooltip {
                    text: qsTr("Launch KDE Spectacle App")
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 22
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 5. SAVE MODIFIER INDICATOR (Fixed Width 78px, Reactive to Shift)
            StyledRect {
                id: btnSaveMod
                implicitWidth: 78
                implicitHeight: 34
                radius: 17
                color: root.shiftHeld ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                border.color: root.shiftHeld ? Colours.palette.m3secondary : Colours.palette.m3outlineVariant
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                StateLayer {
                    radius: 17
                    onPressed: root.shiftHeld = true
                    onReleased: root.shiftHeld = false
                    onCanceled: root.shiftHeld = false
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: root.shiftHeld ? "save" : "content_copy"
                        fontStyle: Tokens.font.icon.small
                        color: root.shiftHeld ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: root.shiftHeld ? qsTr("Save") : qsTr("Copy")
                        font: Tokens.font.label.medium
                        color: root.shiftHeld ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }

                Tooltip {
                    text: qsTr("Hold Shift while capturing to save to disk. Default is copy to clipboard.")
                }
            }

            // 6. CLOSE BUTTON
            IconButton {
                id: btnClose
                icon: "close"
                onClicked: root.dismiss()
                Tooltip {
                    text: qsTr("Close (Esc)")
                }
            }
        }
    }
}
