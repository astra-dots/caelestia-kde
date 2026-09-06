pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg", "gif"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg", "gif"]

    readonly property list<string> validVideoTypes: []
    readonly property list<string> validVideoExtensions: []

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    function isValidVideoByName(name: string): bool {
        return false;
    }

    function isVideo(name: string): bool {
        return false;
    }

    function isAnimated(name: string): bool {
        if (!name) return false;
        return name.endsWith(".gif");
    }
}
