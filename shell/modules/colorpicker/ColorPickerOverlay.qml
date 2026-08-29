pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

PanelWindow {
    id: root

    property bool active: ColorPicker.active
    property int mouseX: 0
    property int mouseY: 0
    // "hex" | "rgb" | "hsl"
    property string format: "hex"
    property color currentColor: "#000000"

    // Loupe grid parameters
    readonly property int gridCells: 13 // 13x13 pixel grid
    readonly property int cellSize: 14  // 14x14 pixels per cell
    readonly property int loupeDiameter: gridCells * cellSize // 182 px

    visible: active
    color: "transparent"

    WlrLayershell.namespace: "caelestia-color-picker-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Connections {
        target: ColorPicker
        function onCycleFormatRequested() {
            root.cycleFormat();
        }
        function onCommitPickRequested() {
            root.commitPick();
        }
    }

    onActiveChanged: {
        if (root.active) {
            captureProcess.running = true;
            keyHandler.forceActiveFocus();
        } else {
            PixelReader.clear();
        }
    }

    function dismiss(): void {
        ColorPicker.active = false;
    }

    function cycleFormat(): void {
        if (root.format === "hex") root.format = "rgb";
        else if (root.format === "rgb") root.format = "hsl";
        else root.format = "hex";
    }

    function getFormattedColor(): string {
        if (root.format === "rgb") return PixelReader.rgb(root.mouseX, root.mouseY);
        if (root.format === "hsl") return PixelReader.hsl(root.mouseX, root.mouseY);
        return PixelReader.hex(root.mouseX, root.mouseY);
    }

    function commitPick(): void {
        const code = getFormattedColor();
        dismiss();
        Quickshell.execDetached(["bash", "-c", `echo -n "${code}" | wl-copy`]);
        if (typeof Toaster !== "undefined" && Toaster.toast) {
            Toaster.toast(code, qsTr("Color copied to clipboard"), "colorize");
        } else {
            Quickshell.execDetached(["notify-send", "Color Picker", `Color ${code} copied to clipboard!`, "-a", "ColorPicker"]);
        }
    }

    Process {
        id: captureProcess

        command: ["bash", "-c", `
            TMP_SNAP="${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/caelestia-colorpicker-snap.png"
            spectacle -f -b -n -o "$TMP_SNAP" 2>/dev/null || true
            echo "$TMP_SNAP"
        `]

        stdout: StdioCollector {
            id: snapOut

            onStreamFinished: {
                const path = snapOut.text.trim();
                if (path !== "") {
                    PixelReader.load(path);
                    root.updateSample();
                }
            }
        }
    }

    function updateSample(): void {
        if (PixelReader.loaded) {
            root.currentColor = PixelReader.pixel(root.mouseX, root.mouseY);
        }
    }

    // Keyboard controls
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_C) {
                root.commitPick();
                event.accepted = true;
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Tab) {
                root.cycleFormat();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                root.mouseX = Math.max(0, root.mouseX - 1);
                root.updateSample();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                root.mouseX = Math.min(root.width - 1, root.mouseX + 1);
                root.updateSample();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.mouseY = Math.max(0, root.mouseY - 1);
                root.updateSample();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.mouseY = Math.min(root.height - 1, root.mouseY + 1);
                root.updateSample();
                event.accepted = true;
            }
        }
    }

    // Fullscreen Mouse Interception
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPositionChanged: (mouse) => {
            root.mouseX = Math.round(mouse.x);
            root.mouseY = Math.round(mouse.y);
            root.updateSample();
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.commitPick();
            } else {
                root.dismiss();
            }
        }
    }

    // Floating Magnifier & Minimal Material You 3 Capsule Card
    Item {
        id: floatingContainer

        readonly property real cardW: 360
        readonly property real totalW: Math.max(root.loupeDiameter + 24, cardW)
        readonly property real totalH: root.loupeDiameter + infoCard.implicitHeight + 16

        readonly property bool flipX: (root.mouseX + totalW + 36) > root.width
        readonly property bool flipY: (root.mouseY + totalH + 36) > root.height

        x: flipX ? Math.max(16, root.mouseX - totalW - 24) : Math.min(root.width - totalW - 16, root.mouseX + 24)
        y: flipY ? Math.max(16, root.mouseY - totalH - 24) : Math.min(root.height - totalH - 16, root.mouseY + 24)
        width: totalW
        height: totalH

        Behavior on x { NumberAnimation { duration: 40; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 40; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // 1. Perfectly Clipped Circular Loupe (With Material 3 Concentric Ring)
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: root.loupeDiameter + 12
                implicitHeight: root.loupeDiameter + 12

                // Outer Drop Shadow Glow Ring
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Colours.palette.m3surfaceContainerLowest
                    border.color: Colours.palette.m3outlineVariant
                    border.width: 1
                }

                // Primary Accent Swatch Ring
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "transparent"
                    border.color: Colours.palette.m3primary
                    border.width: 3
                }

                // True Hardware-Clipped Circle Magnifier
                StyledClippingRect {
                    id: circularClip
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: width / 2
                    clip: true
                    color: "black"

                    // The Scaled Nearest-Neighbor Screen Snapshot
                    Image {
                        id: zoomedImage
                        source: (PixelReader.loaded && PixelReader.imagePath) ? ("file://" + PixelReader.imagePath) : ""
                        smooth: false // Nearest-neighbor scaling for crisp individual pixels
                        mipmap: false
                        asynchronous: false

                        width: PixelReader.imageWidth * root.cellSize
                        height: PixelReader.imageHeight * root.cellSize

                        // Offset so target pixel is dead center in the circle
                        x: (circularClip.width / 2) - (root.mouseX * root.cellSize + root.cellSize / 2)
                        y: (circularClip.height / 2) - (root.mouseY * root.cellSize + root.cellSize / 2)
                    }

                    // Pixel Grid Overlay: Vertical Lines
                    Repeater {
                        model: root.gridCells + 1
                        Rectangle {
                            required property int index
                            x: index * root.cellSize
                            y: 0
                            width: 1
                            height: circularClip.height
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }
                    }

                    // Pixel Grid Overlay: Horizontal Lines
                    Repeater {
                        model: root.gridCells + 1
                        Rectangle {
                            required property int index
                            x: 0
                            y: index * root.cellSize
                            width: circularClip.width
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }
                    }

                    // Center Target Reticle Box
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize
                        height: root.cellSize
                        color: "transparent"
                        border.color: "#ffffff"
                        border.width: 1.5
                        radius: 2

                        // Outer contrast ring so it's visible on pure white
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -1
                            color: "transparent"
                            border.color: "#000000"
                            border.width: 1
                            radius: 3
                        }

                        // Center Dot Indicator
                        Rectangle {
                            anchors.centerIn: parent
                            width: 3
                            height: 3
                            radius: 1.5
                            color: "#ffffff"
                        }
                    }
                }
            }

            // 2. Ultra-Clean, Wide (360px) Single-Format Material You 3 Pill Card
            StyledRect {
                id: infoCard
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: floatingContainer.cardW
                implicitHeight: 60
                radius: 20
                color: Colours.palette.m3surfaceContainerHigh
                border.color: Colours.palette.m3outlineVariant
                border.width: 1.5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    // Live Color Swatch Squircle (Fixed Size)
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 12
                        color: root.currentColor
                        border.color: Colours.palette.m3outline
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 40 } }
                    }

                    // Active Single Color Code & Coordinates (Fills middle space)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            text: root.getFormattedColor()
                            font: Tokens.font.title.medium
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            text: `X: ${root.mouseX}   Y: ${root.mouseY}`
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Format Switcher Pill Chip (Fixed 76px Width, Right-Aligned, Never Moves)
                    StyledRect {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitWidth: 76
                        implicitHeight: 30
                        radius: 15
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: 15
                            onClicked: root.cycleFormat()
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialIcon {
                                text: "swap_horiz"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3onSecondaryContainer
                            }

                            StyledText {
                                text: root.format.toUpperCase()
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onSecondaryContainer
                            }
                        }

                        Tooltip {
                            text: qsTr("Click or press Space to change format")
                        }
                    }
                }
            }
        }
    }
}
