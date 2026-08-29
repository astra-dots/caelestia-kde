pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item barItem

    readonly property bool active: visibilities.screenshot

    // Selection state
    property real startX: 0
    property real startY: 0
    property real currentX: 0
    property real currentY: 0
    property real mouseX: 0
    property real mouseY: 0
    property bool selecting: false

    readonly property real selX: Math.min(startX, currentX)
    readonly property real selY: Math.min(startY, currentY)
    readonly property real selW: Math.abs(currentX - startX)
    readonly property real selH: Math.abs(currentY - startY)

    // Window Hover state
    property var hoveredWindow: null

    // Track KWin workspace & window list in real-time
    readonly property int currentActiveWsId: (typeof KWinWorkspaceState !== "undefined") ? KWinWorkspaceState.activeId : -1
    readonly property var rawKwinList: (typeof KWinActiveWindowBridge !== "undefined" && KWinActiveWindowBridge.windowList) ? KWinActiveWindowBridge.windowList : []
    readonly property var activeKwinWin: (typeof KWinActiveWindowBridge !== "undefined" && KWinActiveWindowBridge.activeWindow) ? KWinActiveWindowBridge.activeWindow : null

    // Real-time stacking-order filtered active windows
    readonly property var activeWindows: {
        if (!rawKwinList || rawKwinList.length === 0) return [];
        const wsId = root.currentActiveWsId;
        
        let list = rawKwinList.filter(w => {
            if (!w || w.minimized) return false;
            if (wsId !== -1 && w.workspace && typeof w.workspace.id === "number") {
                if (w.workspace.id !== -1 && w.workspace.id !== wsId) return false;
            }
            return (typeof w.x === "number" && typeof w.y === "number" && w.width > 20 && w.height > 20);
        });

        let activeWin = root.activeKwinWin;
        let nonActive = list.filter(w => !activeWin || w.address !== activeWin.address);
        
        nonActive.reverse();
        
        if (activeWin && list.some(w => w.address === activeWin.address)) {
            return [activeWin, ...nonActive];
        }
        return nonActive;
    }

    anchors.fill: parent
    visible: active
    focus: active

    onActiveChanged: {
        if (root.active) {
            root.forceActiveFocus();
        }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: (event) => {
        if (!root.active) return;
        const content = root.barItem ? root.barItem.item : null;
        if (event.key === Qt.Key_Escape) {
            root.visibilities.screenshot = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            if (content) {
                let nextIdx = (content.focusedBtnIndex - 1 + 5) % 5;
                content.selectNavIndex(nextIdx);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            if (content) {
                let nextIdx = (content.focusedBtnIndex + 1) % 5;
                content.selectNavIndex(nextIdx);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (content) {
                content.triggerNavIndex(content.focusedBtnIndex);
            }
            event.accepted = true;
        }
    }

    function dismiss(): void {
        root.selecting = false;
        root.hoveredWindow = null;
        root.visibilities.screenshot = false;
    }

    // Top-most hit-testing: Evaluates front-most window first
    function findWindowAt(x, y) {
        const list = root.activeWindows;
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (w && x >= w.x && x <= (w.x + w.width) && y >= w.y && y <= (w.y + w.height)) {
                return w;
            }
        }
        return null;
    }

    // Process Region Crop
    function completeRegionCrop(rx, ry, rw, rh, saveToFile): void {
        const x = Math.round(rx);
        const y = Math.round(ry);
        const w = Math.round(rw);
        const h = Math.round(rh);
        if (w < 5 || h < 5) return;

        const content = root.barItem ? root.barItem.item : null;
        const delay = (content && content.delaySeconds > 0 ? content.delaySeconds : 0.15);
        const saveDir = `${Paths.pictures}/Screenshots`;
        root.dismiss();

        let script = "";
        if (saveToFile) {
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${saveDir}"; ` +
                `saveFile="${saveDir}/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png"; ` +
                `TMP_FULL=$(mktemp /tmp/qs-full-XXXXXX.png); ` +
                `spectacle -f -b -n -o "$TMP_FULL" || true; ` +
                `if [ -f "$TMP_FULL" ] && [ -s "$TMP_FULL" ]; then ` +
                `  magick "$TMP_FULL" -crop ${w}x${h}+${x}+${y} +repage "$saveFile"; ` +
                `  rm -f "$TMP_FULL"; ` +
                `  wl-copy -t image/png < "$saveFile"; ` +
                `  notify-send "Screenshot Saved & Copied" "Saved to $saveFile & copied to clipboard" -a "Spectacle" -i "spectacle" -h "string:image-path:$saveFile" || true; ` +
                `  spectacle -E "$saveFile" 2>/dev/null || spectacle "$saveFile" 2>/dev/null || true; ` +
                `fi`;
        } else {
            const cacheDir = `${Paths.cache}/screenshots`;
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${cacheDir}"; ` +
                `TMP_FULL=$(mktemp /tmp/qs-full-XXXXXX.png); ` +
                `spectacle -f -b -n -o "$TMP_FULL" || true; ` +
                `if [ -f "$TMP_FULL" ] && [ -s "$TMP_FULL" ]; then ` +
                `  TMP_CROP="${cacheDir}/clip-$(date +%Y%m%d_%H%M%S).png"; ` +
                `  magick "$TMP_FULL" -crop ${w}x${h}+${x}+${y} +repage "$TMP_CROP"; ` +
                `  rm -f "$TMP_FULL"; ` +
                `  wl-copy -t image/png < "$TMP_CROP"; ` +
                `  notify-send "Screenshot Copied" "Copied to clipboard (Hold Shift to also save)" -a "Spectacle" -i "spectacle" -h "string:image-path:$TMP_CROP" || true; ` +
                `  spectacle -E "$TMP_CROP" 2>/dev/null || spectacle "$TMP_CROP" 2>/dev/null || true; ` +
                `fi`;
        }
        Quickshell.execDetached(["bash", "-c", script]);
    }

    // Process Window Click Capture
    function captureWindow(win, saveToFile): void {
        if (!win) return;
        const content = root.barItem ? root.barItem.item : null;
        const delay = (content && content.delaySeconds > 0 ? content.delaySeconds : 0.15);
        const saveDir = `${Paths.pictures}/Screenshots`;

        if (typeof KWinActiveWindowBridge !== "undefined" && win.address) {
            KWinActiveWindowBridge.focusWindow(win.address);
        }

        root.dismiss();

        let script = "";
        if (saveToFile) {
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${saveDir}"; ` +
                `saveFile="${saveDir}/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png"; ` +
                `spectacle -b -a -n -o "$saveFile"; ` +
                `wl-copy -t image/png < "$saveFile"; ` +
                `notify-send "Window Saved & Copied" "Saved to $saveFile & copied to clipboard" -a "Spectacle" -i "spectacle" -h "string:image-path:$saveFile" || true; ` +
                `spectacle -E "$saveFile" 2>/dev/null || spectacle "$saveFile" 2>/dev/null || true`;
        } else {
            const cacheDir = `${Paths.cache}/screenshots`;
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${cacheDir}"; ` +
                `TMP_WIN="${cacheDir}/win-$(date +%Y%m%d_%H%M%S).png"; ` +
                `spectacle -b -a -n -o "$TMP_WIN"; ` +
                `wl-copy -t image/png < "$TMP_WIN"; ` +
                `notify-send "Window Copied" "Copied to clipboard (Hold Shift to also save)" -a "Spectacle" -i "spectacle" -h "string:image-path:$TMP_WIN" || true; ` +
                `spectacle -E "$TMP_WIN" 2>/dev/null || spectacle "$TMP_WIN" 2>/dev/null || true; ` +
                `(sleep 60 && rm -f "$TMP_WIN") &`;
        }
        Quickshell.execDetached(["bash", "-c", script]);
    }

    // Darkened Dimming Backdrop
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        visible: root.active

        // Selection Cutout Border (Only in region mode)
        Rectangle {
            visible: (root.barItem?.item?.captureMode ?? "region") === "region" && root.selecting && root.selW > 2 && root.selH > 2
            x: root.selX
            y: root.selY
            width: root.selW
            height: root.selH
            color: "transparent"
            border.color: Colours.palette.m3primary
            border.width: 2
            radius: 8
        }
    }

    // Dynamic Live Window Hover Outline & Title/App Badge
    Item {
        id: singleWindowHighlighter
        visible: (root.barItem?.item?.captureMode ?? "region") === "window" && root.hoveredWindow !== null
        x: root.hoveredWindow ? root.hoveredWindow.x : 0
        y: root.hoveredWindow ? root.hoveredWindow.y : 0
        width: root.hoveredWindow ? root.hoveredWindow.width : 0
        height: root.hoveredWindow ? root.hoveredWindow.height : 0
        z: 10

        Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
        Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

        // Window Outline Box
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3primary, 0.18)
            border.color: Colours.palette.m3primary
            border.width: 3
            radius: 12
        }

        // App Icon + Title Badge Floating at Top-Left of Window
        StyledRect {
            anchors {
                left: parent.left
                leftMargin: 12
                top: parent.top
                topMargin: 12
            }
            implicitHeight: 32
            implicitWidth: badgeRow.implicitWidth + 20
            radius: 16
            color: Colours.palette.m3surfaceContainerHighest
            border.color: Colours.palette.m3primary
            border.width: 1

            RowLayout {
                id: badgeRow
                anchors.centerIn: parent
                spacing: 6

                IconImage {
                    implicitSize: 18
                    source: Quickshell.iconPath((root.hoveredWindow?.class ?? "").toLowerCase(), "application-x-executable")
                }

                StyledText {
                    text: root.hoveredWindow ? (root.hoveredWindow.title || root.hoveredWindow.class || "") : ""
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3primary
                    elide: Text.ElideRight
                    Layout.maximumWidth: 350
                }
            }
        }
    }

    // Sleek Solid Thin Crosshair Alignment Guides (1px solid lines - ONLY in region mode)
    Item {
        id: crosshairs
        anchors.fill: parent
        visible: root.active && (root.barItem?.item?.captureMode ?? "region") === "region"

        readonly property color guideColor: Qt.rgba(1, 1, 1, 0.45)

        // Crosshairs tracking mouse when idle in region mode
        Shape {
            anchors.fill: parent
            visible: !root.selecting && (root.barItem?.item?.captureMode ?? "region") === "region"

            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: root.mouseX; startY: 0
                PathLine { x: root.mouseX; y: crosshairs.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0; startY: root.mouseY
                PathLine { x: crosshairs.width; y: root.mouseY }
            }
        }

        // Solid thin lines following bounding box edges during selection
        Shape {
            anchors.fill: parent
            visible: root.selecting && root.selW > 2 && root.selH > 2

            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: root.selX; startY: 0
                PathLine { x: root.selX; y: crosshairs.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: root.selX + root.selW; startY: 0
                PathLine { x: root.selX + root.selW; y: crosshairs.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0; startY: root.selY
                PathLine { x: crosshairs.width; y: root.selY }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: crosshairs.guideColor
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0; startY: root.selY + root.selH
                PathLine { x: crosshairs.width; y: root.selY + root.selH }
            }
        }
    }

    // Material 3 Dimension Badge Floating Below Selection (ONLY in region mode)
    StyledRect {
        id: dimensionBadge
        visible: (root.barItem?.item?.captureMode ?? "region") === "region" && root.selecting && root.selW > 10 && root.selH > 10
        x: Math.min(Math.max(root.selX + (root.selW - width) / 2, 20), root.width - width - 20)
        y: (root.selY + root.selH + 40 < root.height) ? (root.selY + root.selH + 10) : (root.selY - height - 10)
        implicitWidth: dimText.implicitWidth + 24
        implicitHeight: 32
        radius: 16
        color: Colours.palette.m3surfaceContainerHighest
        border.color: Colours.palette.m3outlineVariant
        border.width: 1

        StyledText {
            id: dimText
            anchors.centerIn: parent
            text: `${Math.round(root.selW)} × ${Math.round(root.selH)}`
            font: Tokens.font.label.medium
            color: Colours.palette.m3primary
        }
    }

    // Fullscreen Interactive Mouse Tracking & Drag Area
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: {
            const mode = root.barItem?.item?.captureMode ?? "region";
            if (mode === "window") return Qt.PointingHandCursor;
            if (mode === "region") return Qt.CrossCursor;
            return Qt.ArrowCursor;
        }

        onPositionChanged: (mouse) => {
            const content = root.barItem ? root.barItem.item : null;
            if (content) {
                content.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            }
            root.mouseX = mouse.x;
            root.mouseY = mouse.y;

            const mode = content ? content.captureMode : "region";
            if (mode === "window") {
                root.hoveredWindow = root.findWindowAt(mouse.x, mouse.y);
            } else if (mode === "region") {
                root.hoveredWindow = null;
                if (root.selecting && (mouse.buttons & Qt.LeftButton)) {
                    root.currentX = mouse.x;
                    root.currentY = mouse.y;
                }
            } else {
                root.hoveredWindow = null;
            }
        }

        onPressed: (mouse) => {
            const content = root.barItem ? root.barItem.item : null;
            if (content) {
                content.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            }
            if (mouse.button === Qt.RightButton) {
                root.dismiss();
                return;
            }

            // Ignore clicks within the top screenshot bar area
            const bar = root.barItem;
            if (bar && mouse.y < bar.y + bar.height + 15 && mouse.x >= bar.x - 10 && mouse.x <= bar.x + bar.width + 10) {
                return;
            }

            const mode = content ? content.captureMode : "region";
            const isShift = (mouse.modifiers & Qt.ShiftModifier) || (content && content.isSaving);

            if (mode === "window") {
                let winObj = root.hoveredWindow || root.findWindowAt(mouse.x, mouse.y);
                if (winObj) {
                    root.captureWindow(winObj, isShift);
                }
            } else if (mode === "region") {
                root.startX = mouse.x;
                root.startY = mouse.y;
                root.currentX = mouse.x;
                root.currentY = mouse.y;
                root.selecting = true;
            } else {
                root.dismiss();
            }
        }

        onReleased: (mouse) => {
            const content = root.barItem ? root.barItem.item : null;
            if (content) {
                content.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            }
            const mode = content ? content.captureMode : "region";
            const isShift = (mouse.modifiers & Qt.ShiftModifier) || (content && content.isSaving);

            if (mode === "region" && root.selecting) {
                root.selecting = false;
                if (root.selW > 10 && root.selH > 10) {
                    root.completeRegionCrop(root.selX, root.selY, root.selW, root.selH, isShift);
                }
            }
        }

        onWheel: (wheel) => {
            const bar = root.barItem;
            if (bar && wheel.y < bar.y + bar.height + 25 && wheel.y >= bar.y - 15 && wheel.x >= bar.x - 15 && wheel.x <= bar.x + bar.width + 15) {
                const content = root.barItem ? root.barItem.item : null;
                if (content) {
                    if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                        let nextIdx = (content.focusedBtnIndex - 1 + 5) % 5;
                        content.selectNavIndex(nextIdx);
                    } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                        let nextIdx = (content.focusedBtnIndex + 1) % 5;
                        content.selectNavIndex(nextIdx);
                    }
                }
            }
        }
    }
}
