pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.utils

PageBase {
    id: root

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            property string value: "top-left"

            text: qsTr("Top left")
        },
        MenuItem {
            property string value: "top-center"

            text: qsTr("Top center")
        },
        MenuItem {
            property string value: "top-right"

            text: qsTr("Top right")
        },
        MenuItem {
            property string value: "center"

            text: qsTr("Center")
        },
        MenuItem {
            property string value: "bottom-left"

            text: qsTr("Bottom left")
        },
        MenuItem {
            property string value: "bottom-center"

            text: qsTr("Bottom center")
        },
        MenuItem {
            property string value: "bottom-right"

            text: qsTr("Bottom right")
        }
    ]

    readonly property list<MenuItem> alignmentItems: [
        MenuItem {
            property int value: 0

            text: qsTr("Left")
        },
        MenuItem {
            property int value: 1

            text: qsTr("Center")
        },
        MenuItem {
            property int value: 2

            text: qsTr("Right")
        }
    ]

    isSubPage: true
    title: qsTr("Desktop Addons")

    readonly property list<MenuItem> clockStyles: [
        MenuItem { text: qsTr("Classic Horizontal"); icon: "schedule" },
        MenuItem { text: qsTr("M3 Cookie Analog"); icon: "nest_clock_farsight_analog" },
        MenuItem { text: qsTr("M3 Giant 2x2 Digital"); icon: "alarm" },
        MenuItem { text: qsTr("M3 Pill Capsule"); icon: "pill" },
        MenuItem { text: qsTr("M3 Radial Arc Dial"); icon: "timelapse" }
    ]
    readonly property var clockStyleValues: ["classic", "cookie", "giant", "pill", "radial"]

    readonly property list<MenuItem> clockPositions: [
        MenuItem { text: qsTr("Top Left"); icon: "align_horizontal_left" },
        MenuItem { text: qsTr("Top Center"); icon: "align_horizontal_center" },
        MenuItem { text: qsTr("Top Right"); icon: "align_horizontal_right" },
        MenuItem { text: qsTr("Middle Left"); icon: "align_horizontal_left" },
        MenuItem { text: qsTr("Center"); icon: "align_horizontal_center" },
        MenuItem { text: qsTr("Middle Right"); icon: "align_horizontal_right" },
        MenuItem { text: qsTr("Bottom Left"); icon: "align_horizontal_left" },
        MenuItem { text: qsTr("Bottom Center"); icon: "align_horizontal_center" },
        MenuItem { text: qsTr("Bottom Right"); icon: "align_horizontal_right" }
    ]
    readonly property var clockPositionValues: [
        "top-left", "top-center", "top-right",
        "middle-left", "middle-center", "middle-right",
        "bottom-left", "bottom-center", "bottom-right"
    ]

    Item {
        Process {
            id: autoProc
            command: ["python3", `${Quickshell.shellDir}/scripts/wallpaper_clutter_analyzer.py`, Wallpapers.actualCurrent || ""]
            stdout: StdioCollector {
                onStreamFinished: {
                    const bestPos = text.trim();
                    if (bestPos.length > 0) {
                        GlobalConfig.background.desktopClock.position = bestPos;
                        for (let i = 0; i < Quickshell.screens.length; i++) {
                            let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                            if (sConf) sConf.background.desktopClock.resetOption("position");
                        }
                        GlobalConfig.save();
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.padding.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Desktop clock")
                checked: Config.background.desktopClock.enabled
                onToggled: {
                    GlobalConfig.background.desktopClock.enabled = checked;
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                        if (sConf) sConf.background.desktopClock.resetOption("enabled");
                    }
                    GlobalConfig.save();
                }
            }

            SelectRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                label: qsTr("Clock Style")
                subtext: qsTr("Choose between Material You 3 expressive clockfaces")
                menuItems: root.clockStyles
                active: root.clockStyles[Math.max(0, root.clockStyleValues.indexOf(Config.background.desktopClock.style || "classic"))]
                enabled: Config.background.desktopClock.enabled
                onSelected: item => {
                    let idx = root.clockStyles.indexOf(item);
                    if (idx >= 0) {
                        GlobalConfig.background.desktopClock.style = root.clockStyleValues[idx];
                        for (let i = 0; i < Quickshell.screens.length; i++) {
                            let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                            if (sConf) sConf.background.desktopClock.resetOption("style");
                        }
                        GlobalConfig.save();
                    }
                }
            }

            SelectRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                label: qsTr("Clock Position")
                subtext: qsTr("Snap desktop clock to screen sector")
                menuItems: root.clockPositions
                active: root.clockPositions[Math.max(0, root.clockPositionValues.indexOf(Config.background.desktopClock.position || "top-left"))]
                enabled: Config.background.desktopClock.enabled
                onSelected: item => {
                    let idx = root.clockPositions.indexOf(item);
                    if (idx >= 0) {
                        GlobalConfig.background.desktopClock.position = root.clockPositionValues[idx];
                        for (let i = 0; i < Quickshell.screens.length; i++) {
                            let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                            if (sConf) sConf.background.desktopClock.resetOption("position");
                        }
                        GlobalConfig.save();
                    }
                }
            }

            SliderRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                label: qsTr("Clock Size")
                subtext: qsTr("Scale factor for desktop clock")
                value: (Config.background.desktopClock.scale - 0.5) / 1.5
                valueLabel: `${Math.round(Config.background.desktopClock.scale * 100)}%`
                enabled: Config.background.desktopClock.enabled
                onMoved: v => {
                    let scaled = 0.5 + v * 1.5;
                    GlobalConfig.background.desktopClock.scale = Math.round(scaled * 10) / 10;
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                        if (sConf) sConf.background.desktopClock.resetOption("scale");
                    }
                    GlobalConfig.save();
                }
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                text: qsTr("Auto-position on wallpaper change")
                subtext: qsTr("Automatically move clock to the cleanest spot when wallpaper changes")
                checked: Config.background.desktopClock.autoPosition
                enabled: Config.background.desktopClock.enabled
                onToggled: {
                    GlobalConfig.background.desktopClock.autoPosition = checked;
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                        if (sConf) sConf.background.desktopClock.resetOption("autoPosition");
                    }
                    GlobalConfig.save();
                }
            }

            ConnectedRect {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                implicitHeight: autoRowLayout.implicitHeight + autoRowLayout.anchors.margins * 2
                clip: false
                enabled: Config.background.desktopClock.enabled

                RowLayout {
                    id: autoRowLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Smart Auto-Position Now")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Analyze current wallpaper to place clock in cleanest space")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    IconTextButton {
                        icon: "auto_awesome"
                        text: qsTr("Auto-Position")
                        type: ButtonBase.Tonal
                        onClicked: {
                            autoProc.running = true;
                        }
                    }
                }
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                text: qsTr("Desktop lyrics")
                checked: Config.background.desktopLyrics.enabled
                onToggled: {
                    GlobalConfig.background.desktopLyrics.enabled = checked;
                    if (!checked)
                        GlobalConfig.background.desktopLyrics.autoHide = false;
                }
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                text: qsTr("Auto-hide lyrics")
                subtext: qsTr("Hide lyrics when a window is open")
                checked: Config.background.desktopLyrics.autoHide
                onToggled: GlobalConfig.background.desktopLyrics.autoHide = checked
                enabled: Config.background.desktopLyrics.enabled || Config.background.desktopLyrics.autoHide
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                text: qsTr("Background visualiser")
                subtext: qsTr("Show music visualiser on wallpaper (May consume more power)")
                checked: Config.background.visualiser.enabled
                onToggled: {
                    GlobalConfig.background.visualiser.enabled = checked;
                    if (!checked)
                        GlobalConfig.background.visualiser.autoHide = false;
                }
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                text: qsTr("Auto-hide visualiser")
                subtext: qsTr("Hide visualiser when a window is fullscreen")
                checked: Config.background.visualiser.autoHide
                onToggled: GlobalConfig.background.visualiser.autoHide = checked
                enabled: Config.background.visualiser.enabled || Config.background.visualiser.autoHide
            }

            ToggleRow {
                Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
                Layout.fillWidth: true
                last: true
                text: qsTr("Hide on all monitors")
                subtext: qsTr("Also hide on all other monitors if disabled by a window")
                checked: Config.background.visualiser.hideOnAllMonitors
                onToggled: GlobalConfig.background.visualiser.hideOnAllMonitors = checked
                enabled: Config.background.visualiser.enabled && Config.background.visualiser.autoHide
            }
        }

        SectionHeader {
            text: qsTr("Desktop clock")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StepperRow {
                first: true
                Layout.fillWidth: true
                label: qsTr("Scale")
                value: Config.background.desktopClock.scale
                from: 0.5
                to: 3
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.desktopClock.scale = v
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Position")
                active: {
                    for (let i = 0; i < root.positionItems.length; i++) {
                        if (root.positionItems[i].value === Config.background.desktopClock.position)
                            return root.positionItems[i];
                    }
                    return root.positionItems[5];
                }
                menuItems: root.positionItems
                onSelected: item => GlobalConfig.background.desktopClock.position = item.value
            }

            ToggleRow {
                last: true
                Layout.fillWidth: true
                text: qsTr("Invert colors")
                checked: Config.background.desktopClock.invertColors
                onToggled: GlobalConfig.background.desktopClock.invertColors = checked
            }
        }

        SectionHeader {
            text: qsTr("Desktop lyrics")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StepperRow {
                first: true
                Layout.fillWidth: true
                label: qsTr("Scale")
                value: Config.background.desktopLyrics.scale
                from: 0.5
                to: 3
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.desktopLyrics.scale = v
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Position")
                active: {
                    for (let i = 0; i < root.positionItems.length; i++) {
                        if (root.positionItems[i].value === Config.background.desktopLyrics.position)
                            return root.positionItems[i];
                    }
                    return root.positionItems[5];
                }
                menuItems: root.positionItems
                onSelected: item => GlobalConfig.background.desktopLyrics.position = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Alignment")
                active: {
                    for (let i = 0; i < root.alignmentItems.length; i++) {
                        if (root.alignmentItems[i].value === Config.background.desktopLyrics.alignment)
                            return root.alignmentItems[i];
                    }
                    return root.alignmentItems[1];
                }
                menuItems: root.alignmentItems
                onSelected: item => GlobalConfig.background.desktopLyrics.alignment = item.value
            }

            ToggleRow {
                last: true
                Layout.fillWidth: true
                text: qsTr("Invert colors")
                checked: Config.background.desktopLyrics.invertColors
                onToggled: GlobalConfig.background.desktopLyrics.invertColors = checked
            }
        }

        SectionHeader {
            text: qsTr("Visualiser")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ToggleRow {
                first: true
                Layout.fillWidth: true
                text: qsTr("Blur")
                checked: Config.background.visualiser.blur
                onToggled: GlobalConfig.background.visualiser.blur = checked
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Rounding")
                value: Config.background.visualiser.rounding
                from: 0
                to: 1
                stepSize: 0.05
                onMoved: v => GlobalConfig.background.visualiser.rounding = v
            }

            StepperRow {
                last: true
                Layout.fillWidth: true
                label: qsTr("Spacing")
                value: Config.background.visualiser.spacing
                from: 0.5
                to: 3
                stepSize: 0.1
                onMoved: v => GlobalConfig.background.visualiser.spacing = v
            }
        }
    }
}
