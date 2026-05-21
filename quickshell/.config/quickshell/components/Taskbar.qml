pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root

    property int maxWidth: 460
    property int itemWidth: 120
    property var clientsRaw: []
    property string activeAddress: ""

    readonly property var clients: {
        if (!clientsRaw || clientsRaw.length === 0)
            return [];

        const filtered = [];
        for (const client of clientsRaw) {
            if (!client || client.mapped === false)
                continue;

            const address = String(client.address ?? "").trim();
            if (address === "")
                continue;

            const className = String(client.class ?? client.initialClass ?? "App").trim() || "App";
            const title = String(client.title ?? "").trim() || className;
            const workspaceId = Number(client.workspace?.id ?? 0);

            filtered.push({
                address: address,
                className: className,
                title: title,
                workspaceId: workspaceId,
                focusHistoryId: Number(client.focusHistoryID ?? 999999)
            });
        }

        filtered.sort((a, b) => a.focusHistoryId - b.focusHistoryId);
        return filtered;
    }

    visible: clients.length > 0
    implicitHeight: Config.barHeight - 8
    implicitWidth: visible ? Math.min(maxWidth, taskbarList.contentWidth) : 0

    function appIcon(className) {
        const key = String(className || "").toLowerCase();
        if (key.includes("kitty"))
            return "";
        if (key.includes("dolphin"))
            return "";
        if (key.includes("zen") || key.includes("firefox") || key.includes("chrome") || key.includes("browser"))
            return "󰖟";
        if (key.includes("code"))
            return "󰨞";
        if (key.includes("spotify"))
            return "󰓇";
        if (key.includes("discord"))
            return "󰙯";
        return "";
    }

    function focusOrMinimize(address) {
        if (address === activeAddress) {
            Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspacesilent", "special:minimized"]);
            return;
        }
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address]);
    }

    function closeWindow(address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + address]);
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    root.clientsRaw = JSON.parse(data);
                } catch (e) {
                    root.clientsRaw = [];
                }
            }
        }
    }

    Process {
        id: activeProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    root.activeAddress = String(JSON.parse(data)?.address ?? "");
                } catch (e) {
                    root.activeAddress = "";
                }
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!clientsProc.running)
                clientsProc.running = true;
            if (!activeProc.running)
                activeProc.running = true;
        }
    }

    ListView {
        id: taskbarList
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 4
        interactive: false
        model: root.clients

        delegate: BarButton {
            required property var modelData
            required property int index

            active: modelData.address === root.activeAddress
            width: root.itemWidth
            implicitHeight: Config.barHeight - 8

            contentItem: Item {
                implicitWidth: titleRow.implicitWidth
                implicitHeight: titleRow.implicitHeight

                RowLayout {
                    id: titleRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: root.appIcon(modelData.className)
                        color: Config.textColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeNormal
                    }

                    Text {
                        text: modelData.title
                        color: Config.textColor
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.maximumWidth: root.itemWidth - 34
                    }
                }
            }

            onClicked: root.focusOrMinimize(modelData.address)
            onRightClicked: root.closeWindow(modelData.address)
        }
    }
}
