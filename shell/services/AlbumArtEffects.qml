pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool enabled: true
    property bool smoothing: true

    function getShaderUrl(): string {
        return Qt.resolvedUrl("../shaders/albumart/pixelate.frag.qsb");
    }

    onEnabledChanged: saveTimer.restart()
    onSmoothingChanged: saveTimer.restart()

    Timer {
        id: saveTimer
        interval: 300
        repeat: false
        onTriggered: root.save()
    }

    function save(): void {
        const data = {
            enabled: root.enabled,
            smoothing: root.smoothing
        };
        storage.setText(JSON.stringify(data, null, 2));
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Quickshell.env("HOME")}/.config/caelestia/album_art_effects.json`
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object") {
                    if (typeof parsed.enabled === "boolean")
                        root.enabled = parsed.enabled;
                    if (typeof parsed.smoothing === "boolean")
                        root.smoothing = parsed.smoothing;
                }
            } catch (e) {
                console.error("Failed to parse album_art_effects.json:", e);
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => root.save());
            }
        }
    }

    IpcHandler {
        target: "albumArt"

        function get(): string {
            return JSON.stringify({
                enabled: root.enabled,
                smoothing: root.smoothing
            });
        }

        function toggle(): string {
            root.enabled = !root.enabled;
            return "Album art pixelate & reveal " + (root.enabled ? "enabled" : "disabled");
        }

        function toggleSmoothing(): string {
            root.smoothing = !root.smoothing;
            return "Album art adaptive smoothing " + (root.smoothing ? "enabled" : "disabled");
        }
    }
}
