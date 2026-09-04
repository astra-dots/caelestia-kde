pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Services

QtObject {
    id: root

    property var items: []
    property int selectedIndex: 0
    property var mruHistory: []

    function triggerCycleNext(): void {
        if (items.length === 0) return;
        selectedIndex = (selectedIndex + 1) % items.length;
    }

    function triggerCyclePrev(): void {
        if (items.length === 0) return;
        selectedIndex = (selectedIndex - 1 + items.length) % items.length;
    }

    function focusSelectedWindow(): void {
        if (selectedIndex >= 0 && selectedIndex < items.length) {
            const addr = String(items[selectedIndex].address);
            focusWindow(addr);
        }
    }

    function reload(): void {
        updateItems();
    }

    function onActiveWindowChanged(): void {
        const active = KWinActiveWindowBridge.activeWindow;
        if (!active || !active.address) return;
        const addr = String(active.address);
        if (addr.length === 0) return;

        // Move to head of MRU history
        let history = (root.mruHistory || []).slice();
        const idx = history.indexOf(addr);
        if (idx !== -1) {
            history.splice(idx, 1);
        }
        history.unshift(addr);
        root.mruHistory = history;

        updateItems();
    }

    function updateItems(): void {
        const rawList = KWinActiveWindowBridge.windowList || [];
        const winList = rawList.filter(w => w && w.address && !(w.class && w.class.toLowerCase().includes("xwaylandvideobridge")));
        
        // Map available windows by address
        const winMap = new Map();
        for (let i = 0; i < winList.length; i++) {
            winMap.set(String(winList[i].address), winList[i]);
        }

        // Keep only currently existing windows in mruHistory
        let history = (root.mruHistory || []).filter(addr => winMap.has(addr));

        // If KWin currently reports an active window, ensure it is at index 0 of MRU history
        const active = KWinActiveWindowBridge.activeWindow;
        if (active && active.address && winMap.has(String(active.address))) {
            const activeAddr = String(active.address);
            const aIdx = history.indexOf(activeAddr);
            if (aIdx !== -1) {
                history.splice(aIdx, 1);
            }
            history.unshift(activeAddr);
        }

        // For any existing window not yet in mruHistory (e.g. at startup or newly opened window),
        // append to the end of history so it has a deterministic place
        for (let i = 0; i < winList.length; i++) {
            const addr = String(winList[i].address);
            if (!history.includes(addr)) {
                history.push(addr);
            }
        }

        root.mruHistory = history;

        // Helper to format
        const formatClient = (client) => {
            return {
                address: client.address,
                title: client.title || "",
                class: client.class || "",
                iconName: client.iconName || client.class || "",
                workspace: client.workspace?.id || "",
                monitor: "",
                wayland: true,
                size: [client.width || 0, client.height || 0],
                at: [client.x || 0, client.y || 0]
            };
        };

        // Order items strictly by mruHistory
        let sortedItems = [];
        for (let i = 0; i < history.length; i++) {
            const client = winMap.get(history[i]);
            if (client) {
                sortedItems.push(formatClient(client));
            }
        }

        root.items = sortedItems;

        // Clamp selectedIndex if out of bounds
        if (root.selectedIndex >= sortedItems.length) {
            root.selectedIndex = Math.max(0, sortedItems.length - 1);
        }
    }

    function query(search: string): var {
        if (!search)
            return items;
        const lower = search.toLowerCase();
        return items.filter(w => w.title.toLowerCase().includes(lower) || w.class.toLowerCase().includes(lower));
    }

    function focusWindow(address: string): void {
        const addr = String(address);
        if (addr.length > 0) {
            // Optimistically update MRU history immediately so rapid Alt+Tab taps never lag
            let history = (root.mruHistory || []).slice();
            const idx = history.indexOf(addr);
            if (idx !== -1) {
                history.splice(idx, 1);
            }
            history.unshift(addr);
            root.mruHistory = history;
        }
        KWinActiveWindowBridge.focusWindow(address);
    }

    function closeWindow(address: string): void {
        KWinActiveWindowBridge.closeWindow(address);
    }

    Component.onCompleted: {
        updateItems();
        KWinActiveWindowBridge.onWindowListChanged.connect(updateItems);
        KWinActiveWindowBridge.onActiveWindowChanged.connect(onActiveWindowChanged);
    }
}
