pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.config

Switch {
    id: root

    implicitWidth: 46
    implicitHeight: 26

    indicator: Rectangle {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        radius: Config.radiusLarge

        color: root.checked ? Qt.alpha(Config.accentColor, 0.86) : Qt.alpha(Config.surface2Color, 0.46)
        border.width: 1
        border.color: root.checked ? Qt.alpha(Config.textReverseColor, 0.22) : Qt.alpha(Config.textColor, 0.10)

        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }

        Rectangle {
            x: root.checked ? (parent.width - width - 4) : 4
            anchors.verticalCenter: parent.verticalCenter

            width: parent.height - 8
            height: parent.height - 8
            radius: width / 2

            color: root.checked ? Config.textReverseColor : Qt.alpha(Config.textColor, 0.88)

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration
                }
            }

            Behavior on x {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutExpo
                }
            }
        }
    }

    // Remove the default text so it doesn't interfere with the layout
    contentItem: Item {}
}
