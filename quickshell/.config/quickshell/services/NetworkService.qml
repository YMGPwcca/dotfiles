pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var accessPoints: []
    property var savedSsids: []
    property bool wifiEnabled: true
    property string wifiInterface: ""
    property string connectedSsid: ""
    property int connectedSignal: 0
    property string connectingSsid: ""
    property double connectingStartedAt: 0
    property int connectingMinDurationMs: 6000
    property int connectingMaxDurationMs: 30000
    property double lastAwakeTick: Date.now()
    readonly property bool scanning: rescanProc.running
    readonly property string systemIcon: {
        if (!wifiEnabled)
            return "󰤮";
        if (connectedSsid !== "")
            return getWifiIcon(connectedSignal, true);
        return "󰤫";
    }

    function splitNmcli(line, delimiter, maxParts) {
        var parts = [];
        var current = "";
        var escaped = false;

        for (let i = 0; i < line.length; i++) {
            const ch = line[i];

            if (escaped) {
                current += ch;
                escaped = false;
                continue;
            }

            if (ch === "\\") {
                escaped = true;
                continue;
            }

            if (ch === delimiter && (maxParts <= 0 || parts.length < maxParts - 1)) {
                parts.push(current);
                current = "";
                continue;
            }

            current += ch;
        }

        parts.push(current);
        return parts;
    }
    function getWifiIcon(signal, connected) {
        const isConnected = connected === undefined ? signal > 0 : connected;

        if (!isConnected)
            return "󰤫";

        if (signal > 80)
            return "󰤨";
        if (signal > 60)
            return "󰤥";
        if (signal > 40)
            return "󰤢";
        if (signal > 20)
            return "󰤟";
        return "󰤟";
    }

    // Status text
    readonly property string statusText: {
        if (!wifiEnabled)
            return "Off";

        if (connectedSsid !== "")
            return connectedSsid;

        // If enabled but not connected
        return "On";
    }

    function toggleWifi() {
        const cmd = wifiEnabled ? "off" : "on";
        toggleWifiProc.command = ["nmcli", "radio", "wifi", cmd];
        toggleWifiProc.running = true;
    }

    function scan() {
        if (!scanning)
            rescanProc.running = true;
    }

    function disconnect() {
        if (wifiInterface !== "") {
            console.log("Disconnecting interface: " + wifiInterface);
            root.connectingSsid = "";
            disconnectProc.command = ["nmcli", "dev", "disconnect", wifiInterface];
            disconnectProc.running = true;
        }
    }

    function connect(ssid, password) {
        console.log("Attempting to connect to:", ssid);
        root.connectingSsid = ssid; // Mark which one we are trying
        root.connectingStartedAt = Date.now();

        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        } else {
            // Try connecting using saved profile
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        }
        connectProc.running = true;
    }

    function finishConnectingIfReady() {
        if (root.connectingSsid === "")
            return;

        const elapsed = Date.now() - root.connectingStartedAt;
        const minDurationReached = elapsed >= root.connectingMinDurationMs;
        const targetConnected = root.connectedSsid !== "" && root.connectedSsid === root.connectingSsid;

        if (targetConnected && minDurationReached)
            root.connectingSsid = "";
    }

    function forget(ssid) {
        console.log("Forgetting network: " + ssid);
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    // Internal function to clean up failed connections
    function cleanUpBadConnection(ssid) {
        console.warn("Connection failed. Removing invalid profile for: " + ssid);
        // Uses forgetProc to delete, since it is the same logic
        forget(ssid);
    }

    // --- PROCESSES ---

    // Connection Process
    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: data => console.log("[Wifi] " + data)
        }
        stderr: SplitParser {
            onRead: data => console.error("[Wifi Error] " + data)
        }

        onExited: code => {
            // If exit code is 0, success. Otherwise, there was an error (wrong password, timeout, etc).
            if (code !== 0) {
                console.error("Failed to connect. Exit code: " + code);

                // IF FAILED: Delete the created profile so it doesn't remain incorrectly marked as "Saved"
                if (root.connectingSsid !== "") {
                    root.cleanUpBadConnection(root.connectingSsid);
                }
                root.connectingSsid = "";
            } else {
                console.log("Connected successfully!");
            }

            // Reset state and update lists
            getSavedProc.running = true;
            currentConnectionProc.running = true;
            getNetworksProc.running = true;
        }
    }

    Timer {
        id: connectGuardTimer
        interval: 500
        repeat: true
        running: root.connectingSsid !== ""
        onTriggered: {
            root.finishConnectingIfReady();
            if (Date.now() - root.connectingStartedAt >= root.connectingMaxDurationMs)
                root.connectingSsid = "";
        }
    }

    // Detect long timer gaps (typically suspend/resume) and force a fresh scan.
    Timer {
        id: resumeWatchdogTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            const now = Date.now();
            const elapsed = now - root.lastAwakeTick;
            root.lastAwakeTick = now;

            if (elapsed > 15000 && root.wifiEnabled) {
                currentConnectionProc.running = true;
                getSavedProc.running = true;
                if (!rescanProc.running)
                    rescanProc.running = true;
            }
        }
    }

    // Detect Wifi Interface
    Process {
        id: findInterfaceProc
        command: ["nmcli", "-g", "DEVICE,TYPE", "device"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.trim().split("\n");
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "wifi") {
                        root.wifiInterface = parts[0];
                    }
                });
            }
        }
    }

    // Status Monitor (Enabled/Disabled)
    Process {
        id: statusProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled = (data.trim() === "enabled");
                if (root.wifiEnabled)
                    currentConnectionProc.running = true;
                if (root.wifiEnabled)
                    getSavedProc.running = true;
                else {
                    root.connectedSsid = "";
                    root.connectedSignal = 0;
                }
                getNetworksProc.running = true;
            }
        }
    }

    // Current Connection State
    Process {
        id: currentConnectionProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let foundConnection = "";
                const previousSsid = root.connectedSsid;

                lines.forEach(line => {
                    const parts = splitNmcli(line, ":", 4);
                    if (parts.length < 4)
                        return;

                    if (parts[1] === "wifi" && parts[2] === "connected") {
                        foundConnection = parts[3] !== "--" ? parts[3] : "";
                    }
                });
                if (foundConnection !== "") {
                    root.connectedSsid = foundConnection;
                    if (foundConnection !== previousSsid)
                        root.connectedSignal = 0;
                } else {
                    root.connectedSsid = "";
                    root.connectedSignal = 0;
                }

                root.finishConnectingIfReady();
            }
        }
    }

    // Toggle On/Off
    Process {
        id: toggleWifiProc
        onExited: {
            statusProc.running = true;
            currentConnectionProc.running = true;
        }
    }

    // Rescan (Refresh)
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            currentConnectionProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // Disconnect
    Process {
        id: disconnectProc
        onExited: {
            currentConnectionProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // Forget Network
    Process {
        id: forgetProc
        // The command is defined dynamically before running
        onExited: {
            currentConnectionProc.running = true;
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // Automatic Update Timer
    Timer {
        interval: 10000
        running: root.wifiEnabled
        repeat: true
        onTriggered: {
            currentConnectionProc.running = true;
            getSavedProc.running = true;
            getNetworksProc.running = true;
        }
    }

    // List Saved Networks
    Process {
        id: getSavedProc
        command: ["nmcli", "-g", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var savedList = [];
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        savedList.push(parts[0]);
                    }
                });
                root.savedSsids = savedList;
            }
        }
    }

    // List Available Networks (Scan)
    Process {
        id: getNetworksProc
        command: ["nmcli", "-g", "IN-USE,SIGNAL,SSID,SECURITY,BSSID,CHAN,RATE", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                var tempParams = [];
                const seen = new Set();
                let hasConnectedEntry = false;
                const savedSsids = Array.isArray(root.savedSsids) ? root.savedSsids : [];

                lines.forEach(line => {
                    if (line.length < 5)
                        return;
                    const parts = splitNmcli(line, ":", 7);
                    if (parts.length < 7)
                        return;

                    const inUse = parts[0] === "*";
                    const signal = parseInt(parts[1]) || 0;
                    const ssid = parts[2];
                    const security = parts[3];
                    const bssid = parts[4];
                    const channel = parts[5];
                    const rate = parts[6];

                    if (!ssid)
                        return;
                    if (seen.has(ssid))
                        return; // Avoid visual duplicates
                    seen.add(ssid);

                    const isSaved = savedSsids.includes(ssid);
                    const isActive = inUse || ssid === root.connectedSsid;

                    if (isActive) {
                        hasConnectedEntry = true;
                        root.connectedSsid = ssid;
                        root.connectedSignal = signal;
                    }

                    tempParams.push({
                        ssid: ssid,
                        signal: signal,
                        active: isActive,
                        secure: security.length > 0,
                        securityType: security || "Open",
                        saved: isSaved,
                        bssid: bssid,
                        channel: channel,
                        rate: rate
                    });
                });

                if (root.connectedSsid !== "" && !hasConnectedEntry) {
                    tempParams.unshift({
                        ssid: root.connectedSsid,
                        signal: root.connectedSignal,
                        active: true,
                        secure: true,
                        securityType: "Unknown",
                        saved: savedSsids.includes(root.connectedSsid),
                        bssid: "",
                        channel: "",
                        rate: ""
                    });
                }

                root.finishConnectingIfReady();

                // Sort: Connected > Saved > Signal
                tempParams.sort((a, b) => {
                    if (a.active)
                        return -1;
                    if (b.active)
                        return 1;
                    if (a.saved && !b.saved)
                        return -1;
                    if (!a.saved && b.saved)
                        return 1;
                    return b.signal - a.signal;
                });

                root.accessPoints = tempParams;
            }
        }
    }
}
