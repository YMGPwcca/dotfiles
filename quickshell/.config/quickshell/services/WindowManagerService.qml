pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Main boolean property for other modules to query
    readonly property bool anyModuleOpen: openWindowsCount > 0
    readonly property bool anyBarShown: visibleBarCount > 0
    readonly property bool barVisibleForPopups: anyBarShown && !activeWindowFullscreen
    property int openWindowsCount: 0
    property int visibleBarCount: 0
    property bool activeWindowFullscreen: false

    // List to know EXACTLY what is open
    property var activeModules: ({})
    property var visibleBars: ({})

    function registerOpen(moduleName) {
        if (!activeModules[moduleName]) {
            let copy = activeModules;
            copy[moduleName] = true;
            activeModules = copy;
            openWindowsCount++;
        }
    }

    function registerClose(moduleName) {
        if (activeModules[moduleName]) {
            let copy = activeModules;
            delete copy[moduleName];
            activeModules = copy;
            openWindowsCount--;
        }
    }

    function setBarShown(barName, shown) {
        let copy = visibleBars;
        const wasShown = copy[barName] === true;

        if (shown && !wasShown) {
            copy[barName] = true;
            visibleBarCount++;
        } else if (!shown && wasShown) {
            delete copy[barName];
            visibleBarCount = Math.max(0, visibleBarCount - 1);
        }

        visibleBars = copy;
    }

    Process {
        id: activeWindowFullscreenProc
        command: ["bash", "-c", "hyprctl activewindow -j 2>/dev/null | jq -r '((.fullscreen // 0) != 0) or ((.fullscreenClient // 0) != 0)'"]

        stdout: SplitParser {
            onRead: data => root.activeWindowFullscreen = data.trim() === "true"
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: activeWindowFullscreenProc.running = true
    }

    onAnyModuleOpenChanged: {
        if (anyModuleOpen) {
            createFile.running = true;
        } else {
            removeFile.running = true;
        }
    }

    // Initial cleanup to avoid remnants in case of errors
    Component.onCompleted: {
        removeFile.running = true;
    }

    // Control file
    Process {
        id: createFile
        command: ["touch", "/tmp/QsAnyModuleIsOpen"]
    }

    Process {
        id: removeFile
        command: ["rm", "-f", "/tmp/QsAnyModuleIsOpen"]
    }
}
