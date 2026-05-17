pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: rootScope

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: window

            required property var modelData
            screen: modelData

            // Only shows if there are active popups
            visible: NotificationService.activePopupCount > 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.namespace: "qs_modules"

            anchors {
                top: true
                right: true
            }

            margins {
                top: 10
                right: 0
            }

            readonly property int entryOffset: 90
            readonly property int screenRightPadding: 10

            implicitWidth: Config.notifWidth + entryOffset + screenRightPadding
            implicitHeight: notifListView.contentHeight

            color: "transparent"

            // Empty mask for when there are no notifications
            Region {
                id: emptyRegion
            }

            mask: (NotificationService.activePopupCount > 0 && implicitHeight > 0) ? null : emptyRegion

            ListView {
                id: notifListView
                anchors.fill: parent

                // Use the stable history list. Filtering to a computed popup
                // array recreates delegates and makes existing cards flash.
                model: NotificationService.notifications

                spacing: 0
                interactive: false

                // Repositioning animation
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Config.animDuration
                        easing.type: Easing.OutQuad
                    }
                }

                delegate: Item {
                    required property var modelData

                    width: notifListView.width
                    height: card.implicitHeight

                    NotificationCard {
                        id: card

                        wrapper: modelData
                        popupMode: true
                        restingX: window.entryOffset
                        entryFromX: notifListView.width
                    }
                }
            }
        }
    }
}
