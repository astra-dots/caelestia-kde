pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components.misc

Singleton {
    id: root

    property list<var> ddcMonitors: []
    readonly property var ddcMonitorMap: {
        const map = {};
        for (const m of ddcMonitors)
            map[m.connector] = m;
        return map;
    }
    readonly property list<Monitor> monitors: variants.instances // qmllint disable incompatible-type
    property bool appleDisplayPresent: false

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen); // qmllint disable missing-property
    }

    function getMonitor(query: string): var {
        if (query === "active") {
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.focused) ?? (monitors.length > 0 ? monitors[0] : null); // qmllint disable missing-property
        }

        if (query.startsWith("model:")) {
            const model = query.slice(6);
            return monitors.find(m => m.modelData.model === model); // qmllint disable missing-property
        }

        if (query.startsWith("serial:")) {
            const serial = query.slice(7);
            return monitors.find(m => m.modelData.serialNumber === serial); // qmllint disable missing-property
        }

        if (query.startsWith("id:")) {
            const id = parseInt(query.slice(3), 10);
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.id === id); // qmllint disable missing-property
        }

        return monitors.find(m => m.modelData.name === query); // qmllint disable missing-property
    }

    function increaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
    }

    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
    }

    onMonitorsChanged: {
        ddcMonitors = [];
        ddcProc.running = true;
    }

    Variants {
        id: variants

        model: Quickshell.screens // Don't respect excluded screens cause ipc

        Monitor {}
    }

    Process {
        running: true
        command: ["sh", "-c", "asdbctl get"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: root.appleDisplayPresent = text.trim().length > 0
        }
    }

    Process {
        id: ddcProc

        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: root.ddcMonitors = text.trim().split("\n\n").filter(d => d.includes("I2C bus:") && d.includes("DRM connector:")).map(d => ({
                        busNum: d.match(/I2C bus:[ ]*\/dev\/i2c-([0-9]+)/)[1],
                        connector: d.match(/DRM connector:\s+(.*)/)[1].replace(/^card\d+-/, "") // strip "card1-"
                    }))
        }
    }

    // Native Wayland listener
    Connections {
        target: BrightnessWatcher

        function onBrightnessChanged(outputName: string, value: real): void {
            const monitor = root.getMonitor(outputName);
            if (monitor) {
                monitor.hasKdeBrightness = true;
                if (Math.round(monitor.brightness * 100) !== Math.round(value * 100)) {
                    monitor.brightness = value;
                }
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    IpcHandler {
        function get(): real {
            return getFor("active");
        }

        // Allows searching by active/model/serial/id/name
        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor)
                return "Invalid monitor: " + query;

            let targetBrightness;
            if (value.endsWith("%-")) {
                const percent = parseFloat(value.slice(0, -2));
                targetBrightness = monitor.brightness - (percent / 100);
            } else if (value.startsWith("+") && value.endsWith("%")) {
                const percent = parseFloat(value.slice(1, -1));
                targetBrightness = monitor.brightness + (percent / 100);
            } else if (value.endsWith("%")) {
                const percent = parseFloat(value.slice(0, -1));
                targetBrightness = percent / 100;
            } else if (value.startsWith("+")) {
                const increment = parseFloat(value.slice(1));
                targetBrightness = monitor.brightness + increment;
            } else if (value.endsWith("-")) {
                const decrement = parseFloat(value.slice(0, -1));
                targetBrightness = monitor.brightness - decrement;
            } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
                return `Invalid brightness format: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;
            } else {
                targetBrightness = parseFloat(value);
            }

            if (isNaN(targetBrightness))
                return `Failed to parse value: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;

            monitor.setBrightness(targetBrightness);

            return `Set monitor ${monitor.modelData.name} brightness to ${+monitor.brightness.toFixed(2)}`;
        }

        target: "brightness"
    }

    component Monitor: QtObject {
        id: monitor

        required property ShellScreen modelData
        readonly property var ddcInfo: root.ddcMonitorMap[modelData.name] ?? null
        readonly property bool isDdc: ddcInfo !== null
        readonly property string busNum: ddcInfo?.busNum ?? ""
        readonly property bool isAppleDisplay: root.appleDisplayPresent && modelData.model.startsWith("StudioDisplay")
        property bool hasKdeBrightness: BrightnessWatcher.brightness(modelData.name) >= 0.0
        property real brightness: 1.0
        property real queuedBrightness: NaN
        property real lastDispatchedBrightness: NaN

        readonly property Process initProc: Process {
            stdout: StdioCollector {
                onStreamFinished: {
                    if (monitor.timer.running || !isNaN(monitor.queuedBrightness))
                        return;
                    if (monitor.isAppleDisplay) {
                        const val = parseInt(text.trim(), 10);
                        if (!isNaN(val))
                            monitor.brightness = val / 101;
                    } else {
                        const parts = text.trim().split(/\s+/);
                        if (parts.length >= 5) {
                            const cur = parseInt(parts[3], 10);
                            const max = parseInt(parts[4], 10);
                            if (!isNaN(cur) && !isNaN(max) && max > 0) {
                                monitor.brightness = cur / max;
                                monitor.lastDispatchedBrightness = cur / max;
                            }
                        }
                    }
                }
            }
        }

        readonly property Timer timer: Timer {
            interval: 100
            onTriggered: {
                if (!isNaN(monitor.queuedBrightness)) {
                    const val = monitor.queuedBrightness;
                    monitor.queuedBrightness = NaN;
                    monitor.applyHardwareBrightness(val);
                    monitor.timer.restart();
                }
            }
        }

        function applyHardwareBrightness(value: real): void {
            const rounded = Math.max(1, Math.min(100, Math.round(value * 100)));
            lastDispatchedBrightness = value;
            if (isAppleDisplay) {
                Quickshell.execDetached(["asdbctl", "set", rounded]);
            } else if (hasKdeBrightness) {
                BrightnessWatcher.setBrightness(modelData.name, value);
            } else if (isDdc) {
                Quickshell.execDetached(["ddcutil", "--noverify", "-b", busNum, "setvcp", "10", rounded]);
            } else {
                BrightnessWatcher.setBrightness(modelData.name, value);
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            const rounded = Math.round(value * 100);
            if (Math.round(brightness * 100) === rounded && Math.round(lastDispatchedBrightness * 100) === rounded)
                return;

            // Immediately update visual UI so slider is buttery smooth with zero delay
            brightness = value;

            if (timer.running) {
                queuedBrightness = value;
            } else {
                applyHardwareBrightness(value);
                timer.restart();
            }
        }

        function fetchBrightness(): void {
            if (timer.running || !isNaN(queuedBrightness))
                return;

            if (isAppleDisplay) {
                initProc.command = ["asdbctl", "get"];
                if (!initProc.running)
                    initProc.running = true;
            } else if (hasKdeBrightness) {
                const val = BrightnessWatcher.brightness(modelData.name);
                if (val >= 0.0)
                    monitor.brightness = val;
            } else if (isDdc) {
                initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
                if (!initProc.running)
                    initProc.running = true;
            } else {
                const val = BrightnessWatcher.brightness(modelData.name);
                if (val >= 0.0)
                    monitor.brightness = val;
            }
        }

        function initBrightness(): void {
            if (isAppleDisplay) {
                initProc.command = ["asdbctl", "get"];
                initProc.running = true;
            } else if (hasKdeBrightness) {
                const val = BrightnessWatcher.brightness(modelData.name);
                if (val >= 0.0)
                    monitor.brightness = val;
            } else if (isDdc) {
                initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
                initProc.running = true;
            } else {
                const val = BrightnessWatcher.brightness(modelData.name);
                if (val >= 0.0)
                    monitor.brightness = val;
            }
        }

        onBusNumChanged: {
            if (busNum.length > 0)
                initBrightness();
        }
        Component.onCompleted: initBrightness()
    }
}
