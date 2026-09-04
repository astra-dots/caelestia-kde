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
    property bool pixelSmoothing: true
    property bool gradientBlur: true
    property bool smearSmoothing: true
    property real pixelGridSize: 16
    property bool pixelAnimation: true

    readonly property bool smoothing: {
        if (root.effectType === "gradient") return root.gradientBlur;
        if (root.effectType === "smear") return root.smearSmoothing;
        return root.pixelSmoothing;
    }

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
    onPixelSmoothingChanged: saveTimer.restart()
    onGradientBlurChanged: saveTimer.restart()
    onSmearSmoothingChanged: saveTimer.restart()
    onPixelGridSizeChanged: saveTimer.restart()
    onPixelAnimationChanged: saveTimer.restart()

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
            pixelSmoothing: root.pixelSmoothing,
            gradientBlur: root.gradientBlur,
            smearSmoothing: root.smearSmoothing,
            pixelGridSize: root.pixelGridSize,
            pixelAnimation: root.pixelAnimation,
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
                    if (typeof parsed.pixelSmoothing === "boolean")
                        root.pixelSmoothing = parsed.pixelSmoothing;
                    else if (typeof parsed.smoothing === "boolean")
                        root.pixelSmoothing = parsed.smoothing;
                    if (typeof parsed.gradientBlur === "boolean")
                        root.gradientBlur = parsed.gradientBlur;
                    else if (typeof parsed.smoothing === "boolean")
                        root.gradientBlur = parsed.smoothing;
                    if (typeof parsed.smearSmoothing === "boolean")
                        root.smearSmoothing = parsed.smearSmoothing;
                    else if (typeof parsed.smoothing === "boolean")
                        root.smearSmoothing = parsed.smoothing;
                    if (typeof parsed.pixelGridSize === "number" && parsed.pixelGridSize >= 4 && parsed.pixelGridSize <= 64)
                        root.pixelGridSize = parsed.pixelGridSize;
                    if (typeof parsed.pixelAnimation === "boolean")
                        root.pixelAnimation = parsed.pixelAnimation;
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
                smoothing: root.smoothing,
                pixelSmoothing: root.pixelSmoothing,
                gradientBlur: root.gradientBlur,
                smearSmoothing: root.smearSmoothing,
                pixelGridSize: root.pixelGridSize,
                pixelAnimation: root.pixelAnimation
            });
        }

        function setEffect(type: string): string {
            if (["pixelate", "gradient", "smear"].includes(type)) {
                root.effectType = type;
                return "Album art effect set to " + type;
            }
            return "Invalid effect type. Choose: pixelate, gradient, smear";
        }

        function setGridSize(size: real): string {
            if (size >= 4 && size <= 64) {
                root.pixelGridSize = Math.round(size);
                return "Album art pixel grid size set to " + root.pixelGridSize;
            }
            return "Invalid grid size. Must be between 4 and 64";
        }

        function toggle(): string {
            root.enabled = !root.enabled;
            return "Album art effect " + (root.enabled ? "enabled" : "disabled");
        }

        function toggleSmoothing(): string {
            if (root.effectType === "gradient") {
                root.gradientBlur = !root.gradientBlur;
                return "Album art deep Kawase blur " + (root.gradientBlur ? "enabled" : "disabled");
            } else if (root.effectType === "smear") {
                root.smearSmoothing = !root.smearSmoothing;
                return "Album art ultra-smooth blending " + (root.smearSmoothing ? "enabled" : "disabled");
            } else {
                root.pixelSmoothing = !root.pixelSmoothing;
                return "Album art adaptive color smoothing " + (root.pixelSmoothing ? "enabled" : "disabled");
            }
        }

        function togglePixelAnimation(): string {
            root.pixelAnimation = !root.pixelAnimation;
            return "Album art pixel animation " + (root.pixelAnimation ? "enabled" : "disabled");
        }
    }
}
