pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    property string layoutStyle: "bento"
    property bool showPinnedOnOpen: true
    property list<string> pins: [
        "antigravity",
        "visual-studio-code",
        "system-monitoring-center",
        "systemsettings"
    ]

    readonly property list<DesktopEntry> pinnedEntries: {
        if (!root.pins || root.pins.length === 0)
            return [];

        const allApps = DesktopEntries.applications.values.filter(a => a && a.id && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id));
        const res = [];
        for (const pid of root.pins) {
            const match = allApps.find(a => a.id.toLowerCase() === pid.toLowerCase() || a.id.toLowerCase().includes(pid.toLowerCase()) || (a.name && a.name.toLowerCase() === pid.toLowerCase()));
            if (match && !res.some(r => r.id === match.id)) {
                res.push(match);
            }
        }
        return res;
    }

    function isPinned(appId: string): bool {
        if (!appId)
            return false;
        return root.pins.some(p => p.toLowerCase() === appId.toLowerCase() || appId.toLowerCase().includes(p.toLowerCase()));
    }

    function togglePin(appId: string): void {
        if (!appId)
            return;
        const list = [...root.pins];
        const idx = list.findIndex(p => p.toLowerCase() === appId.toLowerCase() || appId.toLowerCase().includes(p.toLowerCase()));
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(appId);
        }
        root.pins = list;
        save();
    }

    function unpin(appId: string): void {
        if (!appId)
            return;
        const list = root.pins.filter(p => p.toLowerCase() !== appId.toLowerCase() && !appId.toLowerCase().includes(p.toLowerCase()));
        root.pins = list;
        save();
    }

    function movePin(fromIdx: int, toIdx: int): void {
        if (fromIdx < 0 || fromIdx >= root.pins.length || toIdx < 0 || toIdx >= root.pins.length || fromIdx === toIdx)
            return;
        const list = [...root.pins];
        const [item] = list.splice(fromIdx, 1);
        list.splice(toIdx, 0, item);
        root.pins = list;
        save();
    }

    function setPins(newPins: var): void {
        if (!Array.isArray(newPins))
            return;
        root.pins = newPins;
        save();
    }

    function save(): void {
        const data = {
            layoutStyle: root.layoutStyle,
            showPinnedOnOpen: root.showPinnedOnOpen,
            pins: root.pins
        };
        storage.setText(JSON.stringify(data, null, 2));
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/launcher_pinned.json`
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    root.pins = parsed;
                } else if (parsed && typeof parsed === "object") {
                    if (Array.isArray(parsed.pins))
                        root.pins = parsed.pins;
                    if (typeof parsed.layoutStyle === "string")
                        root.layoutStyle = parsed.layoutStyle;
                    if (typeof parsed.showPinnedOnOpen === "boolean")
                        root.showPinnedOnOpen = parsed.showPinnedOnOpen;
                }
            } catch (e) {
                console.error("Failed to parse launcher_pinned.json:", e);
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => root.save());
            }
        }
    }
}
