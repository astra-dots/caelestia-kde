pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Services
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

    property var spicyLyrics: null
    readonly property bool hasSpicyLyrics: Boolean(root.isSpotify && root.spicyLyrics && root.spicyLyrics.lines && root.spicyLyrics.lines.length > 0)
    readonly property string syncType: root.spicyLyrics?.type ?? "None"
    readonly property var lyricLines: root.spicyLyrics?.lines ?? []

    readonly property real leadOffset: 0.06
    readonly property real effectivePosition: (Players.active?.position ?? 0) + (Lyrics.offset / 1000.0) + root.leadOffset

    function requestLyrics(): void {
        if (!root.isSpotify) return;
        const uri = Players.active?.trackId ?? "";
        const uriParam = uri ? ("?uri=" + encodeURIComponent(uri)) : "";
        Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/lyrics" + uriParam]);
        Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/refresh"]);
    }

    onIsSpotifyChanged: {
        if (root.isSpotify) {
            root.requestLyrics();
        }
    }

    function indexForTime(timeSeconds: real): int {
        if (!root.hasSpicyLyrics || root.lyricLines.length === 0) return -1;
        const lines = root.lyricLines;
        let low = 0;
        let high = lines.length - 1;
        let ans = -1;

        while (low <= high) {
            const mid = Math.floor((low + high) / 2);
            if (lines[mid].startTime <= timeSeconds) {
                ans = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return ans;
    }

    function timeForIndex(index: int): real {
        if (!root.hasSpicyLyrics || index < 0 || index >= root.lyricLines.length) return -1;
        return root.lyricLines[index].startTime ?? -1;
    }

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
                    Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/lyrics"]);
                } else if (line.startsWith("LYRICS:")) {
                    try {
                        const lyricsData = JSON.parse(line.substring(7));
                        if (lyricsData && lyricsData.lines && lyricsData.lines.length > 0) {
                            root.spicyLyrics = lyricsData;
                        } else {
                            root.spicyLyrics = null;
                        }
                    } catch (e) {
                        root.spicyLyrics = null;
                    }
                } else if (line.startsWith("STATE:")) {
                    try {
                        const state = JSON.parse(line.substring(6));
                        const isNewTrack = state.uri && state.uri !== root.currentTrackUri;
                        if (isNewTrack) {
                            root.isDebouncing = false;
                            debounceTimer.stop();
                            root.isLiked = Boolean(state.isLiked);
                            if (root.spicyLyrics && root.spicyLyrics.uri !== state.uri) {
                                root.spicyLyrics = null;
                            }
                            root.requestLyrics();
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
