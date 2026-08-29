pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var dockInstance: null

    function registerDock(dock): void {
        console.log("[DockService] Registered dock instance");
        root.dockInstance = dock;
    }

    function activateAppAtIndex(index: int): void {
        console.log("[DockService] activateAppAtIndex called with index:", index);
        if (root.dockInstance && typeof root.dockInstance.activateAppAtIndex === "function") {
            root.dockInstance.activateAppAtIndex(index);
        } else {
            console.warn("[DockService] No dockInstance registered!");
        }
    }
}
