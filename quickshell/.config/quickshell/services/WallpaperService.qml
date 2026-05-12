pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    function getState(path, fallback) {
        return StateService.get(path, fallback);
    }

    function setState(path, value) {
        StateService.set(path, value);
    }

    property bool pickerVisible: false
    property string currentWallpaper: expandWallpaperPath(getState("wallpaper.current", ""))
    property var wallpapers: []
    property var selectedWallpapers: []
    property bool confirmDelete: false

    property string searchQuery: ""
    property string currentCategory: "all" // "all" | "favorites"
    property var favorites: getState("wallpaper.favorites", [])

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.local/wallpapers"
    readonly property string dotfilesWallpaperDir: StateService.dotfilesPath + "/local/.local/wallpapers"
    readonly property string portalFilePickerScriptPath: Qt.resolvedUrl("../scripts/portal-file-picker.py").toString().replace("file://", "")
    readonly property int selectedCount: selectedWallpapers.length

    readonly property var filteredWallpapers: {
        let list = currentCategory === "favorites" ? wallpapers.filter(w => favorites.includes(relativePath(w))) : wallpapers;

        if (searchQuery) {
            const q = searchQuery.toLowerCase();
            list = list.filter(w => fileName(w).toLowerCase().includes(q));
        }

        return list;
    }

    readonly property var transitions: ["wipe", "wave", "grow", "center", "outer", "any"]

    Component.onCompleted: {
        refreshWallpapers();
        getCurrentWallpaper();
    }

    Connections {
        target: StateService

        function onStateLoaded() {
            root.currentWallpaper = root.expandWallpaperPath(getState("wallpaper.current", ""));
            root.favorites = getState("wallpaper.favorites", []);
        }
    }

    function fileName(path: string): string {
        return path.split("/").pop();
    }

    function relativePath(path: string): string {
        return path.startsWith(wallpaperDir + "/") ? path.slice(wallpaperDir.length + 1) : path;
    }

    function expandWallpaperPath(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("~/"))
            return Quickshell.env("HOME") + "/" + path.slice(2);
        if (path.startsWith("/"))
            return path;
        return wallpaperDir + "/" + path;
    }

    function storedWallpaperPath(path: string): string {
        if (path.startsWith(wallpaperDir + "/"))
            return path.slice(wallpaperDir.length + 1);
        if (path.startsWith(dotfilesWallpaperDir + "/"))
            return path.slice(dotfilesWallpaperDir.length + 1);
        return path;
    }

    function toggleFavorite(path: string) {
        const rel = relativePath(path);
        let favs = [...favorites];
        const idx = favs.indexOf(rel);
        if (idx >= 0)
            favs.splice(idx, 1);
        else
            favs.push(rel);
        favorites = favs;
        setState("wallpaper.favorites", favs);
    }

    function isFavorite(path: string): bool {
        return favorites.includes(relativePath(path));
    }

    function show() {
        refreshWallpapers();
        selectedWallpapers = [];
        confirmDelete = false;
        searchQuery = "";
        currentCategory = "all";
        pickerVisible = true;
    }

    function hide() {
        pickerVisible = false;
        selectedWallpapers = [];
        confirmDelete = false;
    }

    function toggle() {
        if (pickerVisible)
            hide();
        else
            show();
    }

    function isSelected(path: string): bool {
        return selectedWallpapers.includes(path);
    }

    function toggleSelection(path: string) {
        if (isSelected(path)) {
            selectedWallpapers = selectedWallpapers.filter(w => w !== path);
        } else {
            selectedWallpapers = [...selectedWallpapers, path];
        }
        confirmDelete = false;
    }

    function selectOnly(path: string) {
        selectedWallpapers = [path];
        confirmDelete = false;
    }

    function clearSelection() {
        selectedWallpapers = [];
        confirmDelete = false;
    }

    function setWallpaper(path: string) {
        const transition = transitions[Math.floor(Math.random() * transitions.length)];
        const duration = (Math.random() * 1.5 + 0.5).toFixed(1);

        setWallpaperProc.command = ["awww", "img", path, "--transition-type", transition, "--transition-duration", duration, "--transition-fps", "60", "--transition-step", "90"];
        setWallpaperProc.running = true;

        const storedPath = storedWallpaperPath(path);

        currentWallpaper = path;
        setState("wallpaper.current", storedPath);

        writeCurrentProc.command = ["bash", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "bash", storedPath, wallpaperDir + "/.current"];
        writeCurrentProc.running = true;

        hide();
    }

    function applySelected() {
        if (selectedWallpapers.length === 1)
            setWallpaper(selectedWallpapers[0]);
    }

    function setRandomWallpaper() {
        if (wallpapers.length === 0)
            return;

        const available = wallpapers.filter(w => w !== currentWallpaper);
        if (available.length === 0)
            return;

        const randomIndex = Math.floor(Math.random() * available.length);
        setWallpaper(available[randomIndex]);
    }

    function requestDelete() {
        if (selectedWallpapers.length === 0)
            return;

        if (selectedWallpapers.length === 1)
            deleteSelected();
        else
            confirmDelete = true;
    }

    function deleteSelected() {
        if (selectedWallpapers.length === 0)
            return;

        let rmPaths = [];
        for (let i = 0; i < selectedWallpapers.length; i++) {
            const path = selectedWallpapers[i];
            rmPaths.push("'" + path + "'");
            wallpapers = wallpapers.filter(w => w !== path);
            if (currentWallpaper === path)
                currentWallpaper = "";
        }

        deleteWallpaperProc.command = ["sh", "-c", "rm " + rmPaths.join(" ")];
        deleteWallpaperProc.running = true;

        selectedWallpapers = [];
        confirmDelete = false;
    }

    function cancelDelete() {
        confirmDelete = false;
    }

    function importWallpaperPaths(paths) {
        if (!paths || paths.length === 0 || importWallpapersProc.running)
            return;

        console.log("[Wallpaper] Importing paths:", JSON.stringify(paths));
        importWallpapersProc.command = [
            "bash", "-c", "dest=\"$1\"; mkdir -p \"$dest\" && shift && for file in \"$@\"; do [ -f \"$file\" ] || continue; cp -- \"$file\" \"$dest\"/; done",
            "bash", wallpaperDir, ...paths
        ];
        importWallpapersProc.running = true;
    }

    function addWallpapers() {
        if (addWallpapersProc.running)
            return;
        hide();
        addWallpapersProc.running = true;
    }

    function refreshWallpapers() {
        listWallpapersProc.running = true;
    }

    function getCurrentWallpaper() {
        getCurrentProc.running = true;
    }

    Process {
        id: listWallpapersProc
        property var _buffer: []
        command: ["bash", "-c", "ls -1 '" + root.wallpaperDir + "'/*.{png,jpg,jpeg,webp,gif} 2>/dev/null | sort"]

        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed && !trimmed.includes("*"))
                    listWallpapersProc._buffer.push(trimmed);
            }
        }

        onStarted: listWallpapersProc._buffer = []
        onExited: root.wallpapers = listWallpapersProc._buffer
    }

    Process {
        id: setWallpaperProc
        onExited: exitCode => {
            if (exitCode === 0)
                console.log("[Wallpaper] Wallpaper changed successfully");
            else
                console.error("[Wallpaper] Failed to change wallpaper");
        }
    }

    Process {
        id: getCurrentProc
        command: ["awww", "query"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/image:\s*(.+)/);
                if (match) {
                    root.currentWallpaper = match[1].trim();
                    root.setState("wallpaper.current", root.storedWallpaperPath(root.currentWallpaper));
                }
            }
        }
    }

    Process {
        id: addWallpapersProc
        property var _selectedPaths: []
        command: ["python3", root.portalFilePickerScriptPath]

        stdout: SplitParser {
            onRead: data => {
                const lines = data.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line)
                        addWallpapersProc._selectedPaths.push(line);
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line)
                    console.error("[Wallpaper] Portal picker error:", line);
            }
        }

        onStarted: addWallpapersProc._selectedPaths = []
        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Wallpaper] Portal returned paths:", JSON.stringify(addWallpapersProc._selectedPaths));
                root.importWallpaperPaths(addWallpapersProc._selectedPaths);
            } else if (exitCode === 1) {
                root.show();
            } else if (exitCode !== 1) {
                console.error("[Wallpaper] Add wallpapers exited with code", exitCode);
                root.show();
            }
        }
    }

    Process {
        id: importWallpapersProc
        stderr: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line)
                    console.error("[Wallpaper] Import wallpapers error:", line);
            }
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                root.refreshWallpapers();
                root.show();
            } else {
                console.error("[Wallpaper] Import wallpapers exited with code", exitCode);
                root.show();
            }
        }
    }

    Process {
        id: writeCurrentProc
    }

    Process {
        id: deleteWallpaperProc
    }
}
