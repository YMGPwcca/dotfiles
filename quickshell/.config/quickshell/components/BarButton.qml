pragma ComponentBehavior: Bound
import QtQuick
import qs.config

Rectangle {
    id: root

    property bool active: false
    property Item contentItem: null
    readonly property bool hovered: mouseArea.containsMouse

    signal clicked
    signal rightClicked

    implicitWidth: (contentItem?.implicitWidth ?? 0) + (Config.padding * 2)
    implicitHeight: Config.barHeight - 8
    radius: height / 2

    color: {
        if (active)
            return Qt.alpha(Config.accentColor, 0.22);
        if (hovered)
            return Qt.alpha(Config.surface2Color, 0.66);
        return Qt.alpha(Config.surface1Color, 0.42);
    }
    border.width: 1
    border.color: active ? Qt.alpha(Config.accentColor, 0.42) : Qt.alpha(Config.textColor, hovered ? 0.20 : 0.12)

    Behavior on color {
        ColorAnimation {
            duration: Config.animDuration
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
