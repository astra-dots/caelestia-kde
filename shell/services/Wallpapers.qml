pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpapers/Minimal-Paper.png")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    property string currentMediaFilter: "All"

    property var filteredList: {
        const res = wallpapers.entries || [];
        if (currentMediaFilter === "Image") {
            return res.filter(w => !Images.isAnimated(w.relativePath));
        } else if (currentMediaFilter === "Animated") {
            return res.filter(w => Images.isAnimated(w.relativePath));
        }
        return res;
    }

    readonly property var categories: {
        let dummy = root.list;
        const baseDir = Paths.wallsdir;
        let cats = [];
        for (let i = 0; i < root.list.length; i++) {
            let p = root.list[i].parentDir;
            if (p !== baseDir) {
                let cat = p.slice(baseDir.length + 1);
                if (cat.includes("/")) cat = cat.slice(0, cat.indexOf("/"));
                if (!cats.includes(cat)) cats.push(cat);
            }
        }
        return ["Main"].concat(cats.sort());
    }

    readonly property var grouped: {
        let dummy = root.list;
        const baseDir = Paths.wallsdir;
        let grp = { "Main": [] };
        for (let i = 0; i < root.list.length; i++) {
            let w = root.list[i];
            let p = w.parentDir;
            if (p === baseDir) {
                grp["Main"].push(w);
            } else {
                let cat = p.slice(baseDir.length + 1);
                if (cat.includes("/")) cat = cat.slice(0, cat.indexOf("/"));
                if (!grp[cat]) grp[cat] = [];
                grp[cat].push(w);
            }
        }
        return grp;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        // caelestia-cli's wallpaper command has no random ("-r") support for
        // live/video wallpapers, so pick randomly ourselves and set it via the
        // same path (setWallpaper) used for a specific wallpaper, which does.
        if (!root.list || root.list.length === 0) return;
        let idx = Math.floor(Math.random() * root.list.length);
        if (root.list.length > 1 && root.list[idx].path === actualCurrent)
            idx = (idx + 1) % root.list.length;
        setWallpaper(root.list[idx].path);
    }

    function setNextSequential(): void {
        if (!root.list || root.list.length === 0) return;
        let idx = -1;
        for (let i = 0; i < root.list.length; i++) {
            if (root.list[i].path === actualCurrent) {
                idx = i;
                break;
            }
        }
        idx = (idx + 1) % root.list.length;
        setWallpaper(root.list[idx].path);
    }

    function next(): void {
        if (GlobalConfig.background.slideshowRandom) {
            setRandom();
        } else {
            setNextSequential();
        }
    }

    function setWallpaper(path: string): void {
        const cleanPath = String(path || "").replace(/^file:\/\//, "");
        actualCurrent = cleanPath;
        const script = 'caelestia wallpaper -f "$1" ' + root.smartArg.join(" ");
        Quickshell.execDetached(["sh", "-c", script, "--", cleanPath]);
        syncPlasmaWallpaper(cleanPath);
    }

    // Mirrors the wallpaper onto Plasma's own desktop background so it doesn't
    // stay stale (e.g. showing the deploy-time default) whenever the shell
    // isn't running to keep it in sync itself, such as after a crash/exit.
    function syncPlasmaWallpaper(imagePath: string): void {
        if (!imagePath)
            return;
        const script = 'var allDesktops = desktops();' +
            'for (var i = 0; i < allDesktops.length; i++) {' +
            '    var d = allDesktops[i];' +
            '    d.wallpaperPlugin = "org.kde.image";' +
            '    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];' +
            '    d.writeConfig("Image", "file://" + ' + JSON.stringify(imagePath) + ');' +
            '}';
        Quickshell.execDetached(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    function thumbFor(path: string): string {
        return String(path || "").replace(/^file:\/\//, "");
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: filteredList
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Files
        nameFilters: Images.validImageExtensions.map(e => `*.${e}`)
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
