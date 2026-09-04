pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property bool isSpotify: {
        const id = Players.active?.identity?.toLowerCase() ?? "";
        return id.includes("spotify");
    }

    property bool isLiked: false
    property string currentTrackUri: ""
    property var upcomingTrack: null
    readonly property string upcomingTitle: root.upcomingTrack?.title ?? ""
    readonly property string upcomingArtist: root.upcomingTrack?.artist ?? ""
    readonly property string upcomingAlbum: root.upcomingTrack?.album ?? ""
    readonly property string upcomingArtUrl: root.upcomingTrack?.artUrl ?? ""
    readonly property bool hasUpcoming: root.isSpotify && root.upcomingTitle.length > 0
    property bool isConnected: false
    property bool isDebouncing: false

    Timer {
        id: debounceTimer
        interval: 1000
        onTriggered: root.isDebouncing = false
    }

    function toggleLike(): void {
        if (root.isDebouncing) return;
        root.isDebouncing = true;
        debounceTimer.restart();

        // Optimistic UI state toggle
        const targetState = !root.isLiked;
        root.isLiked = targetState;

        if (targetState) {
            if (typeof Toaster !== "undefined" && Toaster.toast) {
                Toaster.toast(qsTr("Added to Liked Songs"), Players.active?.trackTitle ?? "", "favorite");
            }
        } else {
            if (typeof Toaster !== "undefined" && Toaster.toast) {
                Toaster.toast(qsTr("Removed from Liked Songs"), Players.active?.trackTitle ?? "", "favorite_border");
            }
        }

        // Single atomic command dispatch
        Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/toggle"]);
    }

    function skipNext(): void {
        Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/skip"]);
    }

    Process {
        id: bridgeProcess

        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/caelestia/scripts/spotify_bridge.py"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.startsWith("READY:")) {
                    root.isConnected = true;
                    Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/state"]);
                } else if (line.startsWith("STATE:")) {
                    try {
                        const state = JSON.parse(line.substring(6));
                        const isNewTrack = state.uri && state.uri !== root.currentTrackUri;
                        if (isNewTrack) {
                            root.isDebouncing = false;
                            debounceTimer.stop();
                            root.isLiked = Boolean(state.isLiked);
                        } else if (!root.isDebouncing) {
                            root.isLiked = Boolean(state.isLiked);
                        }
                        root.currentTrackUri = state.uri || "";
                        root.upcomingTrack = state.upcoming || null;
                    } catch (e) {}
                }
            }
        }
    }
}
