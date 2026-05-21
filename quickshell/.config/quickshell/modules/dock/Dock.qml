pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"

Scope {
    id: root

    readonly property int gapIn: 6
    readonly property int gapOut: 10

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            WlrLayershell.namespace: "qs_modules_dock"
            WlrLayershell.layer: WlrLayer.Top

            implicitHeight: Config.barHeight + 10
            color: "transparent"
            screen: modelData
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: height

            anchors {
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                id: dockContent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                width: Math.min(parent.width - (root.gapOut * 2), 1080)
                height: parent.height - 8
                radius: height / 2
                color: Qt.alpha(Config.surface0Color, 0.86)
                border.width: 1
                border.color: Qt.alpha(Config.textColor, 0.16)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: root.gapIn

                    BarButton {
                        id: launcherButton
                        active: LauncherService.visible
                        implicitHeight: Config.barHeight - 6
                        implicitWidth: Config.barHeight + 4
                        onClicked: LauncherService.show()

                        contentItem: Text {
                            text: "󰣇"
                            color: Config.textColor
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeIconSmall
                            anchors.centerIn: parent
                        }
                    }

                    Taskbar {
                        maxWidth: dockContent.width - launcherButton.width - (root.gapIn * 2)
                    }
                }
            }
        }
    }
}
