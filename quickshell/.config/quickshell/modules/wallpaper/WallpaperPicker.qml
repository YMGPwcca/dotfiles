pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../components/"
import qs.services
import qs.config

PanelWindow {
    id: root

    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WallpaperService.pickerVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs_modules"

    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (WallpaperService.selectedCount > 0) {
                WallpaperService.clearSelection();
            } else {
                content.forceActiveFocus();
                WallpaperService.hide();
            }
        }
    }

    AnimatedPopup {
        id: pickerAnim
        anchors.centerIn: parent
        width: Math.min(900, root.width - 100)
        height: Math.min(650, root.height - 100)
        shown: WallpaperService.pickerVisible
        easingType: Easing.OutBack
        easingOvershoot: 1.1

        Rectangle {
            id: content
            anchors.fill: parent
            radius: Config.radiusLarge
            color: Config.backgroundTransparentColor
            border.color: Qt.alpha(Config.accentColor, 0.2)
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.spacing + 8
                spacing: Config.spacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacing

                    Text {
                        text: "󰸉"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeIcon
                        color: Config.accentColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Wallpapers"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeLarge
                            font.weight: Font.DemiBold
                            color: Config.textColor
                        }

                        Text {
                            text: WallpaperService.filteredWallpapers.length + " images"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            color: Config.surface3Color
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        icon: "󰐕"
                        text: "Add"
                        textColor: Config.successColor
                        hoverTextColor: Config.successColor
                        onClicked: WallpaperService.addWallpapers()
                    }

                    ActionButton {
                        icon: "󰒝"
                        text: "Random"
                        textColor: Config.accentColor
                        hoverTextColor: Config.accentColor
                        onClicked: WallpaperService.setRandomWallpaper()
                    }

                    ActionButton {
                        icon: "󰅖"
                        iconSize: Config.fontSizeNormal
                        hoverColor: Config.errorColor
                        textColor: Config.subtextColor
                        hoverTextColor: Config.textColor
                        onClicked: {
                            content.forceActiveFocus();
                            WallpaperService.hide();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Config.radius
                    color: Config.surface1Color

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: Config.textColor
                            clip: true
                            onTextChanged: WallpaperService.searchQuery = text

                            Text {
                                visible: !parent.text
                                text: "Search wallpapers..."
                                font: parent.font
                                color: Config.mutedColor
                            }
                        }

                        ActionButton {
                            visible: searchInput.text !== ""
                            icon: "󰅖"
                            size: 24
                            iconSize: Config.fontSizeSmall
                            textColor: Config.subtextColor
                            hoverTextColor: Config.textColor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ActionButton {
                        icon: "󰉖"
                        text: "All"
                        baseColor: WallpaperService.currentCategory === "all" ? Config.accentColor : Config.surface1Color
                        hoverColor: WallpaperService.currentCategory === "all" ? Config.accentColor : Config.surface2Color
                        textColor: WallpaperService.currentCategory === "all" ? Config.textReverseColor : Config.subtextColor
                        hoverTextColor: WallpaperService.currentCategory === "all" ? Config.textReverseColor : Config.textColor
                        onClicked: WallpaperService.currentCategory = "all"
                    }

                    ActionButton {
                        icon: "󰋑"
                        text: "Favorites"
                        baseColor: WallpaperService.currentCategory === "favorites" ? Config.accentColor : Config.surface1Color
                        hoverColor: WallpaperService.currentCategory === "favorites" ? Config.accentColor : Config.surface2Color
                        textColor: WallpaperService.currentCategory === "favorites" ? Config.textReverseColor : Config.subtextColor
                        hoverTextColor: WallpaperService.currentCategory === "favorites" ? Config.textReverseColor : Config.textColor
                        onClicked: WallpaperService.currentCategory = "favorites"
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Config.surface1Color
                }

                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 215
                    cellHeight: 150
                    cacheBuffer: 600
                    model: WallpaperService.filteredWallpapers

                    delegate: Item {
                        id: wallpaperItem
                        required property int index
                        required property string modelData

                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        property bool isHovered: itemMouse.containsMouse || fileNameMouse.containsMouse
                        property bool isCurrent: modelData === WallpaperService.currentWallpaper
                        property bool isSelected: WallpaperService.isSelected(modelData)
                        property bool isFav: WallpaperService.isFavorite(modelData)
                        property string displayName: {
                            const name = WallpaperService.fileName(modelData);
                            const dot = name.lastIndexOf(".");
                            return dot > 0 ? name.substring(0, dot) : name;
                        }

                        Rectangle {
                            id: card
                            anchors.fill: parent
                            anchors.margins: 6
                            anchors.bottomMargin: 22
                            radius: Config.radius
                            color: Config.surface0Color
                            border.width: wallpaperItem.isSelected ? 2 : (wallpaperItem.isCurrent ? 2 : (wallpaperItem.isHovered ? 1 : 0))
                            border.color: wallpaperItem.isSelected ? Config.accentColor : (wallpaperItem.isCurrent ? Config.accentColor : Config.surface2Color)
                            scale: wallpaperItem.isHovered ? 1.02 : 1

                            Behavior on border.width {
                                NumberAnimation { duration: Config.animDurationShort }
                            }

                            Behavior on border.color {
                                ColorAnimation { duration: Config.animDurationShort }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Config.animDurationShort
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton

                                onClicked: mouse => {
                                    if (mouse.modifiers & Qt.ControlModifier)
                                        WallpaperService.toggleSelection(wallpaperItem.modelData);
                                    else
                                        WallpaperService.selectOnly(wallpaperItem.modelData);
                                }

                                onDoubleClicked: WallpaperService.setWallpaper(wallpaperItem.modelData)
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Config.radiusSmall
                                    clip: true

                                    Image {
                                        id: thumbnail
                                        anchors.fill: parent
                                        source: "file://" + wallpaperItem.modelData
                                        sourceSize: Qt.size(256, 144)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: Config.radiusSmall
                                color: Config.surface1Color
                                visible: thumbnail.status === Image.Loading

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSizeIcon
                                    color: Config.mutedColor

                                    RotationAnimator on rotation {
                                        from: 0
                                        to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                        running: thumbnail.status === Image.Loading
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: Config.radiusSmall
                                color: Qt.alpha(Config.accentColor, 0.2)
                                visible: wallpaperItem.isSelected
                            }

                            Rectangle {
                                visible: wallpaperItem.isCurrent
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 8
                                width: 24
                                height: 24
                                radius: height / 2
                                color: Config.accentColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: Config.font
                                    font.pixelSize: 12
                                    color: Config.textReverseColor
                                }
                            }

                            Rectangle {
                                id: favBadge
                                visible: wallpaperItem.isHovered || wallpaperItem.isFav
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 24
                                height: 24
                                radius: height / 2
                                color: wallpaperItem.isFav ? Config.errorColor : Qt.alpha(Config.surface0Color, 0.8)

                                Behavior on color {
                                    ColorAnimation { duration: Config.animDurationShort }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: wallpaperItem.isFav ? "󰋑" : "󰋕"
                                    font.family: Config.font
                                    font.pixelSize: 12
                                    color: wallpaperItem.isFav ? Config.textReverseColor : Config.subtextColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WallpaperService.toggleFavorite(wallpaperItem.modelData)
                                }
                            }
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            text: wallpaperItem.displayName
                            font.family: Config.font
                            font.pixelSize: 10
                            color: wallpaperItem.isHovered ? Config.textColor : Config.subtextColor
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter

                            MouseArea {
                                id: fileNameMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton

                                onClicked: mouse => {
                                    if (mouse.modifiers & Qt.ControlModifier)
                                        WallpaperService.toggleSelection(wallpaperItem.modelData);
                                    else
                                        WallpaperService.selectOnly(wallpaperItem.modelData);
                                }

                                onDoubleClicked: WallpaperService.setWallpaper(wallpaperItem.modelData)
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spacing
                        visible: wallpaperGrid.count === 0

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64
                            height: 64
                            radius: 32
                            color: Config.surface1Color

                            Text {
                                anchors.centerIn: parent
                                text: WallpaperService.currentCategory === "favorites" ? "󰋑" : "󰸉"
                                font.family: Config.font
                                font.pixelSize: 28
                                color: Config.subtextColor
                                opacity: 0.5
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (WallpaperService.searchQuery)
                                    return "No results";
                                if (WallpaperService.currentCategory === "favorites")
                                    return "No favorites yet";
                                return "No wallpapers found";
                            }
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: Config.subtextColor
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (WallpaperService.searchQuery)
                                    return "Try a different search term";
                                if (WallpaperService.currentCategory === "favorites")
                                    return "Click the 󰋕 on any wallpaper";
                                return "Add images to ~/.local/wallpapers";
                            }
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            color: Config.mutedColor
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded

                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Config.surface2Color
                            opacity: parent.active ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Config.animDurationShort }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperService.selectedCount > 0 ? 50 : 0
                    radius: Config.radius
                    color: Config.surface0Color
                    visible: Layout.preferredHeight > 0
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.spacing + 4
                        anchors.rightMargin: Config.spacing + 4
                        spacing: Config.spacing

                        Text {
                            text: WallpaperService.selectedCount + " selected"
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeNormal
                            color: Config.subtextColor
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            visible: WallpaperService.confirmDelete
                            spacing: Config.spacing

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Delete " + WallpaperService.selectedCount + " wallpapers?"
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeNormal
                                color: Config.warningColor
                            }

                            ClearButton {
                                icon: "󰄬"
                                text: "Yes"
                                onClicked: WallpaperService.deleteSelected()
                            }

                            ActionButton {
                                icon: "󰅖"
                                text: "No"
                                size: 32
                                onClicked: WallpaperService.cancelDelete()
                            }
                        }

                        Row {
                            visible: !WallpaperService.confirmDelete
                            spacing: Config.spacing

                            ActionButton {
                                visible: WallpaperService.selectedCount === 1
                                icon: "󰄬"
                                text: "Apply"
                                size: 32
                                baseColor: Config.surface1Color
                                hoverColor: Config.accentColor
                                textColor: Config.accentColor
                                hoverTextColor: Config.textReverseColor
                                onClicked: WallpaperService.applySelected()
                            }

                            ClearButton {
                                icon: "󰅖"
                                text: "Delete"
                                onClicked: WallpaperService.requestDelete()
                            }

                            ActionButton {
                                icon: "󰜺"
                                size: 32
                                textColor: Config.subtextColor
                                hoverTextColor: Config.textColor
                                onClicked: WallpaperService.clearSelection()
                            }
                        }
                    }
                }
            }

            Keys.onEscapePressed: {
                if (WallpaperService.confirmDelete) {
                    WallpaperService.cancelDelete();
                } else if (WallpaperService.selectedCount > 0) {
                    WallpaperService.clearSelection();
                } else {
                    content.forceActiveFocus();
                    WallpaperService.hide();
                }
            }
            Keys.onDeletePressed: WallpaperService.requestDelete()
            Keys.onReturnPressed: WallpaperService.applySelected()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_R) {
                    WallpaperService.setRandomWallpaper();
                    event.accepted = true;
                } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                    WallpaperService.selectedWallpapers = [...WallpaperService.filteredWallpapers];
                    event.accepted = true;
                } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
                    searchInput.forceActiveFocus();
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: WallpaperService.pickerVisible
        onCleared: {
            if (WallpaperService.pickerVisible)
                WallpaperService.hide();
        }
    }
}
