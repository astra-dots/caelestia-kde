pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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

    // "region" | "window" | "fullscreen" | "spectacle" | "delay"
    property string captureMode: "region"
    property int delaySeconds: 0
    property bool shiftHeld: false
    readonly property bool isSaving: root.shiftHeld

    // 0: Region, 1: Window, 2: Full Screen, 3: Spectacle, 4: Delay
    property int focusedBtnIndex: root.captureMode === "window" ? 1 : (root.captureMode === "fullscreen" ? 2 : (root.captureMode === "spectacle" ? 3 : (root.captureMode === "delay" ? 4 : 0)))

    implicitHeight: 52
    implicitWidth: contentRow.implicitWidth + 24
    width: implicitWidth
    height: implicitHeight
    focus: true

    MouseArea {
        anchors.fill: parent
        z: 10
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

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    function dismiss(): void {
        root.visibilities.screenshot = false;
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

    // Process Fullscreen Capture
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

    // Shift modifier watcher
    Process {
        id: shiftWatcher
        running: root.visibilities.screenshot

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

    // Fluid liquid stretch indicator pill
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
                target: btnRegion
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
                target: btnWindow
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
                target: btnFull
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
                target: btnSpectacle
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

        // 5. DELAY TIMER CHIP (Nav Index 4)
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
                target: btnDelay
                text: qsTr("Capture Delay (Click: 0s, 3s, 5s, 10s)")
            }
        }

        // 6. SAVE MODIFIER INDICATOR
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
                target: btnSaveMod
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
                target: btnClose
                text: qsTr("Close (Esc)")
            }
        }
    }
}
