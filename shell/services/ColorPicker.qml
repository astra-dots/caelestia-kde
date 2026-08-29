pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool active: false
    signal cycleFormatRequested()
    signal commitPickRequested()

    function pickColor(): void {
        root.active = true;
    }

    function toggle(): void {
        root.active = !root.active;
    }

    function startPick(): void {
        root.active = true;
    }

    function cancel(): void {
        root.active = false;
    }

    function cycleFormat(): void {
        root.cycleFormatRequested();
    }

    function commitPick(): void {
        root.commitPickRequested();
    }
}
