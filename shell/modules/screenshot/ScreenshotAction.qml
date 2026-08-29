pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import qs.services
import qs.utils

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function escapeShellStr(str) {
        if (!str) return "''";
        return str.replace(/'/g, "'\\''");
    }

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "", saveToFile = false) {
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);

        const cropBase = `magick '${escapeShellStr(screenshotPath)}' `
            + `-crop ${rw}x${rh}+${rx}+${ry} +repage`
        const cleanup = `rm -f '${escapeShellStr(screenshotPath)}'`
        const rawSaveDir = saveDir === "" ? "~/Pictures/Screenshots" : saveDir;

        switch (action) {
            case ScreenshotAction.Action.Copy: {
                if (saveToFile) {
                    return [
                        "bash", "-c",
                        `set -euo pipefail; ` +
                        `SAVE_DIR='${escapeShellStr(rawSaveDir)}'; ` +
                        `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                        `mkdir -p "$SAVE_DIR" && ` +
                        `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && ` +
                        `${cropBase} "$saveFile" && ` +
                        `wl-copy -t image/png < "$saveFile"; ` +
                        `notify-send "Screenshot Saved & Copied" "Saved to $saveFile & copied to clipboard" -i "$saveFile" -a "Screenshot" || true; ` +
                        `spectacle -E "$saveFile" 2>/dev/null || spectacle "$saveFile" 2>/dev/null || true; ` +
                        `${cleanup}`
                    ];
                } else {
                    return [
                        "bash", "-c",
                        `set -euo pipefail; ` +
                        `TMPF=$(mktemp /tmp/qs-crop-XXXXXX.png); ` +
                        `${cropBase} "$TMPF" && ` +
                        `wl-copy -t image/png < "$TMPF"; ` +
                        `notify-send "Screenshot Copied" "Copied to clipboard (Hold Shift to also save)" -a "Screenshot" || true; ` +
                        `spectacle -E "$TMPF" 2>/dev/null || spectacle "$TMPF" 2>/dev/null || true; ` +
                        `${cleanup}; (sleep 40 && rm -f "$TMPF") &`
                    ];
                }
            }

            case ScreenshotAction.Action.Edit: {
                return [
                    "bash", "-c",
                    `set -euo pipefail; ` +
                    `SAVE_DIR='${escapeShellStr(rawSaveDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && ` +
                    `${cropBase} "$saveFile" && ` +
                    `wl-copy -t image/png < "$saveFile"; ` +
                    `spectacle -E "$saveFile" 2>/dev/null || spectacle "$saveFile" 2>/dev/null || true; ` +
                    `${cleanup}`
                ];
            }

            case ScreenshotAction.Action.Search: {
                const tmpFile = Paths.runtimeTemp("snip-search.png");
                return [
                    "bash", "-c",
                    `set -euo pipefail; ` +
                    `magick '${escapeShellStr(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage '${tmpFile}' && ` +
                    `URL=$(curl -sF files[]=@'${tmpFile}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url') && ` +
                    `xdg-open "${root.imageSearchEngineBaseUrl}$URL"; ` +
                    `rm -f '${tmpFile}'; ${cleanup}`
                ];
            }

            case ScreenshotAction.Action.CharRecognition: {
                return [
                    "bash", "-c",
                    `set -euo pipefail; TMPF=$(mktemp /tmp/qs-ocr-XXXXXX.png); ` +
                    `${cropBase} -colorspace gray -type grayscale -contrast-stretch 0 -resize 300% "$TMPF" && ` +
                    `TEXT=$(tesseract "$TMPF" stdout 2>/dev/null || true); ` +
                    `printf "%s" "$TEXT" | wl-copy; ` +
                    `notify-send "Text Recognized" "$TEXT" -a "Screenshot" || true; ` +
                    `rm -f "$TMPF"; ${cleanup}`
                ];
            }

            case ScreenshotAction.Action.Record:
            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `spectacle -R r`];

            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}
