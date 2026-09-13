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
    property string themeMode: "song"
    readonly property bool isThemeModeAvailable: root.isSpotify && root.isConnected

    property var spicyLyrics: null
    readonly property bool hasSpicyLyrics: Boolean(root.isSpotify && root.spicyLyrics && root.spicyLyrics.lines && root.spicyLyrics.lines.length > 0)
    readonly property string syncType: root.spicyLyrics?.type ?? "None"
    readonly property var lyricLines: root.spicyLyrics?.lines ?? []

    readonly property real effectivePosition: Players.active?.position ?? 0

    Connections {
        target: Players.active
        ignoreUnknownSignals: true

        function onTrackTitleChanged() {
            root.handleTrackChange();
        }
        function onTrackArtistChanged() {
            root.handleTrackChange();
        }
        function onPostTrackChanged() {
            root.handleTrackChange();
        }
    }

    function normalizeTrackUri(uri: string): string {
        if (!uri) return "";
        const m = uri.match(/[0-9a-zA-Z]{22}/);
        return m ? ("spotify:track:" + m[0]) : uri;
    }

    Timer {
        id: requestLyricsDebounce
        interval: 350
        onTriggered: {
            if (!root.isSpotify) return;
            const uri = root.normalizeTrackUri(Players.active?.trackId ?? root.currentTrackUri);
            const uriParam = uri ? ("?uri=" + encodeURIComponent(uri)) : "";
            Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/lyrics" + uriParam]);
            Quickshell.execDetached(["curl", "-s", "http://127.0.0.1:8999/refresh"]);
        }
    }

    function handleTrackChange(): void {
        if (!root.isSpotify) return;
        const newUri = root.normalizeTrackUri(Players.active?.trackId ?? "");
        if (newUri && newUri !== root.currentTrackUri) {
            root.currentTrackUri = newUri;
            root.spicyLyrics = null;
            root.requestLyrics();
        }
    }

    function requestLyrics(): void {
        if (!root.isSpotify) return;
        requestLyricsDebounce.restart();
    }

    onIsSpotifyChanged: {
        if (root.isSpotify) {
            root.requestLyrics();
            fetchThemeProc.running = true;
        } else {
            root.spicyLyrics = null;
        }
    }

    Connections {
        target: Colours
        ignoreUnknownSignals: true
        function onPaletteChanged() {
            if (root.isSpotify && root.themeMode === "system") {
                Quickshell.execDetached(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify({ mode: "system" }), "http://127.0.0.1:8999/theme-mode"]);
            }
        }
    }

    function indexForTime(timeSeconds: real): int {
        if (!root.hasSpicyLyrics || root.lyricLines.length === 0) return -1;
        if (root.syncType === "Static") return -1;
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
        id: fetchThemeProc
        command: ["curl", "-s", "http://127.0.0.1:8999/theme-mode"]
        stdout: StdioCollector {
            id: fetchThemeStdout
        }
        onExited: {
            try {
                const data = JSON.parse(fetchThemeStdout.text);
                if (data && data.mode) {
                    root.themeMode = data.mode;
                }
            } catch (e) {}
        }
    }

    function toggleThemeMode(): void {
        const nextMode = (root.themeMode === "system") ? "song" : "system";
        root.themeMode = nextMode;
        Quickshell.execDetached(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.stringify({ mode: nextMode }), "http://127.0.0.1:8999/theme-mode"]);
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
                    fetchThemeProc.running = true;
                } else if (line.startsWith("LYRICS:")) {
                    try {
                        const lyricsData = JSON.parse(line.substring(7));
                        if (lyricsData && lyricsData.lines && lyricsData.lines.length > 0) {
                            const trackUri = root.normalizeTrackUri(Players.active?.trackId ?? root.currentTrackUri);
                            const lyricUri = root.normalizeTrackUri(lyricsData.uri ?? "");
                            if (!lyricUri || !trackUri || lyricUri === trackUri) {
                                root.spicyLyrics = lyricsData;
                            } else {
                                root.spicyLyrics = null;
                            }
                        } else {
                            root.spicyLyrics = null;
                        }
                    } catch (e) {
                        root.spicyLyrics = null;
                    }
                } else if (line.startsWith("STATE:")) {
                    try {
                        const state = JSON.parse(line.substring(6));
                        if (state.themeMode) {
                            root.themeMode = state.themeMode;
                        }
                        const normStateUri = root.normalizeTrackUri(state.uri || "");
                        const isNewTrack = normStateUri && normStateUri !== root.currentTrackUri;
                        if (isNewTrack) {
                            root.isDebouncing = false;
                            debounceTimer.stop();
                            root.isLiked = Boolean(state.isLiked);
                            if (root.spicyLyrics && root.normalizeTrackUri(root.spicyLyrics.uri) !== normStateUri) {
                                root.spicyLyrics = null;
                            }
                            root.currentTrackUri = normStateUri;
                            root.requestLyrics();
                        } else if (!root.isDebouncing) {
                            root.isLiked = Boolean(state.isLiked);
                        }
                        if (normStateUri) {
                            root.currentTrackUri = normStateUri;
                        }
                        root.upcomingTrack = state.upcoming || null;
                    } catch (e) {}
                }
            }
        }
    }
}
