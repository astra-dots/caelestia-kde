pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool enabled: true
    // "pixelate" | "gradient" | "smear"
    property string effectType: "pixelate"
    property bool smoothing: true

    function getShaderUrl(): string {
        if (root.effectType === "gradient") {
            return Qt.resolvedUrl("../shaders/albumart/gradient.frag.qsb");
        } else if (root.effectType === "smear") {
            return Qt.resolvedUrl("../shaders/albumart/smear.frag.qsb");
        }
        return Qt.resolvedUrl("../shaders/albumart/pixelate.frag.qsb");
    }

    onEnabledChanged: saveTimer.restart()
    onEffectTypeChanged: saveTimer.restart()
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
            effectType: root.effectType,
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
                    if (typeof parsed.effectType === "string" && ["pixelate", "gradient", "smear"].includes(parsed.effectType))
                        root.effectType = parsed.effectType;
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
                effectType: root.effectType,
                smoothing: root.smoothing
            });
        }

        function setEffect(type: string): string {
            if (["pixelate", "gradient", "smear"].includes(type)) {
                root.effectType = type;
                return "Album art effect set to " + type;
            }
            return "Invalid effect type. Choose: pixelate, gradient, smear";
        }

        function toggle(): string {
            root.enabled = !root.enabled;
            return "Album art effect " + (root.enabled ? "enabled" : "disabled");
        }

        function toggleSmoothing(): string {
            root.smoothing = !root.smoothing;
            return "Album art adaptive smoothing " + (root.smoothing ? "enabled" : "disabled");
        }
    }
}
