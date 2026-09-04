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

PanelWindow {
    id: root

    property bool active: false
    property int delaySeconds: 0
    property bool shiftHeld: false
    readonly property bool isSaving: root.shiftHeld

    // "region" | "window" | "fullscreen" | "spectacle" | "delay"
    property string captureMode: "region"

    // 0: Region, 1: Window, 2: Full Screen, 3: Spectacle, 4: Delay
    property int focusedBtnIndex: root.captureMode === "window" ? 1 : (root.captureMode === "fullscreen" ? 2 : (root.captureMode === "spectacle" ? 3 : (root.captureMode === "delay" ? 4 : 0)))

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

    visible: active
    color: "transparent"

    WlrLayershell.namespace: "caelestia-screenshot-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                let nextIdx = (root.focusedBtnIndex - 1 + 5) % 5;
                root.selectNavIndex(nextIdx);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                let nextIdx = (root.focusedBtnIndex + 1) % 5;
                root.selectNavIndex(nextIdx);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.triggerNavIndex(root.focusedBtnIndex);
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

    Process {
        id: shiftWatcher
        running: root.active

        command: ["python3", "-u", "-c", `
import glob, struct, os, select, sys

EVENT_FORMAT = "qqHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
EV_KEY = 1
KEY_LEFTSHIFT = 42
KEY_RIGHTSHIFT = 54

devices = []
for kbd in glob.glob("/dev/input/by-id/*-event-kbd"):
    try:
        fd = os.open(kbd, os.O_RDONLY | os.O_NONBLOCK)
        devices.append(fd)
    except Exception:
        pass

if not devices:
    sys.exit(0)

shift_count = 0

while True:
    r, _, _ = select.select(devices, [], [])
    for fd in r:
        try:
            data = os.read(fd, EVENT_SIZE * 16)
            for i in range(0, len(data), EVENT_SIZE):
                chunk = data[i:i+EVENT_SIZE]
                if len(chunk) < EVENT_SIZE:
                    continue
                sec, usec, etype, code, value = struct.unpack(EVENT_FORMAT, chunk)
                if etype == EV_KEY and (code == KEY_LEFTSHIFT or code == KEY_RIGHTSHIFT):
                    if value == 1:
                        shift_count += 1
                        if shift_count == 1:
                            print("1", flush=True)
                    elif value == 0:
                        shift_count = max(0, shift_count - 1)
                        if shift_count == 0:
                            print("0", flush=True)
        except Exception:
            pass
`]

        stdout: SplitParser {
            onRead: text => {
                const t = text.trim();
                if (t === "1") {
                    root.shiftHeld = true;
                } else if (t === "0") {
                    root.shiftHeld = false;
                }
            }
        }
    }

    onActiveChanged: {
        if (root.active) {
            root.shiftHeld = false;
            keyHandler.forceActiveFocus();
        }
    }

    onCaptureModeChanged: {
        if (root.captureMode !== "window") {
            root.hoveredWindow = null;
        }
        if (root.captureMode !== "region") {
            root.selecting = false;
        }
    }

    function toggle(): void {
        if (root.active) {
            root.dismiss();
        } else {
            root.captureMode = "region";
            root.focusedBtnIndex = 0;
            root.selecting = false;
            root.shiftHeld = false;
            root.hoveredWindow = null;
            root.active = true;
            mainMouseArea.forceActiveFocus();
        }
    }

    function dismiss(): void {
        root.selecting = false;
        root.shiftHeld = false;
        root.hoveredWindow = null;
        root.active = false;
    }

    function cycleDelay(): void {
        if (root.delaySeconds === 0) root.delaySeconds = 3;
        else if (root.delaySeconds === 3) root.delaySeconds = 5;
        else if (root.delaySeconds === 5) root.delaySeconds = 10;
        else root.delaySeconds = 0;
    }

    function selectNavIndex(idx: int): void {
        root.focusedBtnIndex = Math.max(0, Math.min(4, idx));
        if (root.focusedBtnIndex === 0) {
            root.captureMode = "region";
        } else if (root.focusedBtnIndex === 1) {
            root.captureMode = "window";
        } else if (root.focusedBtnIndex === 2) {
            root.captureMode = "fullscreen";
        } else if (root.focusedBtnIndex === 3) {
            root.captureMode = "spectacle";
        } else if (root.focusedBtnIndex === 4) {
            root.captureMode = "delay";
        }
    }

    function triggerNavIndex(idx: int): void {
        if (idx === 0) {
            root.selectNavIndex(0);
        } else if (idx === 1) {
            root.selectNavIndex(1);
        } else if (idx === 2) {
            root.selectNavIndex(2);
            root.triggerFullScreen(root.isSaving);
        } else if (idx === 3) {
            root.selectNavIndex(3);
            root.triggerSpectacleApp();
        } else if (idx === 4) {
            root.selectNavIndex(4);
            root.cycleDelay();
        }
    }

    // Top-most hit-testing: Evaluates front-most / smaller floating window first
    function findWindowAt(x, y) {
        const list = root.activeWindows;
        const candidates = [];
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (w && x >= w.x && x <= (w.x + w.width) && y >= w.y && y <= (w.y + w.height)) {
                candidates.push(w);
            }
        }
        if (candidates.length === 0) return null;
        if (candidates.length === 1) return candidates[0];

        // When multiple windows cover (x, y) (e.g. a floating window on top of a maximized app):
        // 1. Floating/non-maximized windows take priority over maximized/fullscreen background apps.
        // 2. Smaller window area takes priority over larger windows (dialogs/floating windows sit on top).
        candidates.sort((a, b) => {
            const aMax = (a.maximized || a.fullscreen) ? 1 : 0;
            const bMax = (b.maximized || b.fullscreen) ? 1 : 0;
            if (aMax !== bMax) return aMax - bMax;
            const areaA = (a.width || 0) * (a.height || 0);
            const areaB = (b.width || 0) * (b.height || 0);
            return areaA - areaB;
        });

        return candidates[0];
    }

    // Process Region Crop
    function completeRegionCrop(rx, ry, rw, rh, saveToFile): void {
        const x = Math.round(rx);
        const y = Math.round(ry);
        const w = Math.round(rw);
        const h = Math.round(rh);
        if (w < 5 || h < 5) return;

        const delay = (root.delaySeconds > 0 ? root.delaySeconds : 0.15);
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
        const delay = (root.delaySeconds > 0 ? root.delaySeconds : 0.15);
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

    // Process Fullscreen Capture (Instant, zero lag, high-res preview)
    function triggerFullScreen(saveToFile): void {
        const delay = (root.delaySeconds > 0 ? root.delaySeconds : 0.15);
        const saveDir = `${Paths.pictures}/Screenshots`;
        root.dismiss();

        let script = "";
        if (saveToFile) {
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${saveDir}"; ` +
                `saveFile="${saveDir}/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png"; ` +
                `spectacle -f -b -n -o "$saveFile"; ` +
                `wl-copy -t image/png < "$saveFile"; ` +
                `notify-send "Full Screen Saved & Copied" "Saved to $saveFile & copied to clipboard" -a "Spectacle" -i "spectacle" -h "string:image-path:$saveFile" || true; ` +
                `spectacle -E "$saveFile" 2>/dev/null || spectacle "$saveFile" 2>/dev/null || true`;
        } else {
            const cacheDir = `${Paths.cache}/screenshots`;
            script = `sleep ${delay}; ` +
                `set -euo pipefail; ` +
                `mkdir -p "${cacheDir}"; ` +
                `TMP_FULL="${cacheDir}/full-$(date +%Y%m%d_%H%M%S).png"; ` +
                `spectacle -f -b -n -o "$TMP_FULL"; ` +
                `wl-copy -t image/png < "$TMP_FULL"; ` +
                `notify-send "Full Screen Copied" "Copied to clipboard (Hold Shift to also save)" -a "Spectacle" -i "spectacle" -h "string:image-path:$TMP_FULL" || true; ` +
                `spectacle -E "$TMP_FULL" 2>/dev/null || spectacle "$TMP_FULL" 2>/dev/null || true; ` +
                `(sleep 120 && rm -f "$TMP_FULL") &`;
        }
        Quickshell.execDetached(["bash", "-c", script]);
    }

    // Open Spectacle App Directly
    function triggerSpectacleApp(): void {
        root.dismiss();
        Quickshell.execDetached(["spectacle", "-g"]);
    }

    // Darkened Dimming Backdrop
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        visible: root.active

        // Selection Cutout Border (Only in region mode)
        Rectangle {
            visible: root.captureMode === "region" && root.selecting && root.selW > 2 && root.selH > 2
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
        visible: root.captureMode === "window" && root.hoveredWindow !== null
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
        visible: root.active && root.captureMode === "region"

        readonly property color guideColor: Qt.rgba(1, 1, 1, 0.45)

        // Crosshairs tracking mouse when idle in region mode
        Shape {
            anchors.fill: parent
            visible: !root.selecting && root.captureMode === "region"

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
        visible: root.captureMode === "region" && root.selecting && root.selW > 10 && root.selH > 10
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
            if (root.captureMode === "window") return Qt.PointingHandCursor;
            if (root.captureMode === "region") return Qt.CrossCursor;
            return Qt.ArrowCursor;
        }

        onPositionChanged: (mouse) => {
            root.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            root.mouseX = mouse.x;
            root.mouseY = mouse.y;

            if (root.captureMode === "window") {
                root.hoveredWindow = root.findWindowAt(mouse.x, mouse.y);
            } else if (root.captureMode === "region") {
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
            root.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            if (mouse.button === Qt.RightButton) {
                root.dismiss();
                return;
            }

            // Ignore clicks within the top bar area
            if (mouse.y < pillBar.y + pillBar.height + 15 && mouse.x >= pillBar.x - 10 && mouse.x <= pillBar.x + pillBar.width + 10) {
                return;
            }

            if (root.captureMode === "window") {
                let winObj = root.hoveredWindow || root.findWindowAt(mouse.x, mouse.y);
                if (winObj) {
                    root.captureWindow(winObj, (mouse.modifiers & Qt.ShiftModifier) || root.isSaving);
                }
            } else if (root.captureMode === "region") {
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
            root.shiftHeld = (mouse.modifiers & Qt.ShiftModifier) !== 0;
            const isShift = (mouse.modifiers & Qt.ShiftModifier) || root.isSaving;
            if (root.captureMode === "region" && root.selecting) {
                root.selecting = false;
                const rx = root.selX;
                const ry = root.selY;
                const rw = root.selW;
                const rh = root.selH;
                if (rw > 10 && rh > 10) {
                    root.completeRegionCrop(rx, ry, rw, rh, isShift);
                }
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
            topMargin: root.active ? 18 : -height - 40
            horizontalCenter: parent.horizontalCenter
        }

        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
        border.width: 0
        radius: 28

        implicitHeight: 52
        implicitWidth: contentRow.implicitWidth + 20

        MouseArea {
            anchors.fill: parent
            z: 5
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                if (event.angleDelta.y > 0 || event.angleDelta.x < 0) {
                    let nextIdx = (root.focusedBtnIndex - 1 + 5) % 5;
                    root.selectNavIndex(nextIdx);
                } else if (event.angleDelta.y < 0 || event.angleDelta.x > 0) {
                    let nextIdx = (root.focusedBtnIndex + 1) % 5;
                    root.selectNavIndex(nextIdx);
                }
            }
        }

        Behavior on anchors.topMargin {
            Anim {
                type: Anim.Emphasized
                duration: 300
            }
        }

        // ==========================================
        // FLUID LIQUID TRAIL ACTIVE INDICATOR
        // ==========================================
        Item {
            id: indicatorContainer
            anchors.fill: contentRow
            z: 0

            readonly property var navButtons: [btnRegion, btnWindow, btnFull, btnSpectacle, btnDelay]
            readonly property var currentItem: (root.focusedBtnIndex >= 0 && root.focusedBtnIndex < navButtons.length) ? navButtons[root.focusedBtnIndex] : null

            property real targetPos: currentItem ? currentItem.x : 0
            property real targetSize: currentItem ? currentItem.width : 0

            property real leading: targetPos
            property real trailing: targetPos
            property real currentSize: targetSize
            property real offset: Math.min(leading, trailing)
            property real size: Math.abs(leading - trailing) + currentSize

            StyledRect {
                id: liquidPill
                visible: indicatorContainer.currentItem !== null
                x: indicatorContainer.offset
                y: indicatorContainer.currentItem ? indicatorContainer.currentItem.y : 0
                implicitWidth: indicatorContainer.size
                implicitHeight: indicatorContainer.currentItem ? indicatorContainer.currentItem.height : 34
                radius: 17
                color: Colours.palette.m3primary
                z: 0
            }

            Behavior on leading {
                Anim {
                    type: Anim.Emphasized
                    duration: Tokens.anim.durations.normal
                }
            }

            Behavior on trailing {
                Anim {
                    type: Anim.Emphasized
                    duration: Tokens.anim.durations.normal * 2
                }
            }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6
            z: 1

            // Header Camera Icon Badge
            StyledRect {
                implicitWidth: 34
                implicitHeight: 34
                radius: 17
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
                implicitHeight: 20
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 1. REGION MODE (Nav Index 0)
            StyledRect {
                id: btnRegion
                implicitWidth: regionLayout.implicitWidth + 16
                implicitHeight: 34
                radius: 17
                color: "transparent"

                StateLayer {
                    radius: 17
                    onClicked: root.selectNavIndex(0)
                }

                RowLayout {
                    id: regionLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "crop_free"
                        color: root.focusedBtnIndex === 0 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Region")
                        font: Tokens.font.label.medium
                        color: root.focusedBtnIndex === 0 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Drag anywhere to snip a region & annotate in Spectacle")
                }
            }

            // 2. WINDOW HOVER MODE (Nav Index 1)
            StyledRect {
                id: btnWindow
                implicitWidth: winLayout.implicitWidth + 16
                implicitHeight: 34
                radius: 17
                color: "transparent"

                StateLayer {
                    radius: 17
                    onClicked: root.selectNavIndex(1)
                }

                RowLayout {
                    id: winLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "near_me"
                        color: root.focusedBtnIndex === 1 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Window")
                        font: Tokens.font.label.medium
                        color: root.focusedBtnIndex === 1 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Hover over any window on your desktop to highlight and click to capture")
                }
            }

            // 3. FULLSCREEN BUTTON (Nav Index 2)
            StyledRect {
                id: btnFull
                implicitWidth: fullLayout.implicitWidth + 16
                implicitHeight: 34
                radius: 17
                color: "transparent"

                StateLayer {
                    radius: 17
                    onClicked: {
                        root.selectNavIndex(2);
                        root.triggerFullScreen(root.isSaving);
                    }
                }

                RowLayout {
                    id: fullLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "fullscreen"
                        color: root.focusedBtnIndex === 2 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Full Screen")
                        font: Tokens.font.label.medium
                        color: root.focusedBtnIndex === 2 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Instant Fullscreen Capture")
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 20
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 4. OPEN SPECTACLE BUTTON (Nav Index 3)
            StyledRect {
                id: btnSpectacle
                implicitWidth: specLayout.implicitWidth + 16
                implicitHeight: 34
                radius: 17
                color: "transparent"

                StateLayer {
                    radius: 17
                    onClicked: {
                        root.selectNavIndex(3);
                        root.triggerSpectacleApp();
                    }
                }

                RowLayout {
                    id: specLayout
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "camera"
                        color: root.focusedBtnIndex === 3 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("Spectacle")
                        font: Tokens.font.label.medium
                        color: root.focusedBtnIndex === 3 ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                }

                Tooltip {
                    text: qsTr("Launch KDE Spectacle App")
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 20
                color: Colours.palette.m3outlineVariant
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            // 5. DELAY TIMER CHIP (Nav Index 4 - Fixed 62px width for rock-solid stability)
            StyledRect {
                id: btnDelay
                implicitWidth: 62
                implicitHeight: 34
                radius: 17
                color: "transparent"

                StateLayer {
                    radius: 17
                    onClicked: {
                        root.selectNavIndex(4);
                        root.cycleDelay();
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: "timer"
                        fontStyle: Tokens.font.icon.small
                        color: root.focusedBtnIndex === 4 ? Colours.palette.m3onPrimary : (root.delaySeconds > 0 ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant)
                    }

                    StyledText {
                        text: root.delaySeconds === 0 ? qsTr("0s") : `${root.delaySeconds}s`
                        font: Tokens.font.label.medium
                        color: root.focusedBtnIndex === 4 ? Colours.palette.m3onPrimary : (root.delaySeconds > 0 ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant)
                    }
                }

                Tooltip {
                    text: qsTr("Capture Delay (Click: 0s, 3s, 5s, 10s)")
                }
            }

            // 6. SAVE MODIFIER INDICATOR (Pure status indicator, fixed 78px width, no toggle click)
            StyledRect {
                id: btnSaveMod
                implicitWidth: 78
                implicitHeight: 34
                radius: 17
                color: root.isSaving ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                border.color: root.isSaving ? Colours.palette.m3secondary : Colours.palette.m3outlineVariant
                border.width: root.isSaving ? 2 : 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialIcon {
                        text: root.isSaving ? "save" : "content_copy"
                        fontStyle: Tokens.font.icon.small
                        color: root.isSaving ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: root.isSaving ? qsTr("Save") : qsTr("Copy")
                        font: Tokens.font.label.medium
                        color: root.isSaving ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }

                Tooltip {
                    text: qsTr("Hold Shift key on keyboard while capturing to save to disk. Default is copy to clipboard.")
                }
            }

            // 7. COMPACT CLOSE BUTTON
            StyledRect {
                id: btnClose
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    radius: 16
                    onClicked: root.dismiss()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurface
                }

                Tooltip {
                    text: qsTr("Close (Esc)")
                }
            }
        }
    }
}
