pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import "../../components/"

QsPopupWindow {
    id: root

    popupWidth: 300
    popupMaxHeight: 500
    anchorSide: "left"
    moduleName: "Calendar"
    contentImplicitHeight: calendarContent.implicitHeight

    // Calendar state
    property int displayMonth: today.getMonth()
    property int displayYear: today.getFullYear()
    property bool monthPickerVisible: false
    readonly property date today: TimeService.date
    readonly property var englishLocale: Qt.locale("en_US")
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    function resetToToday() {
        displayMonth = today.getMonth();
        displayYear = today.getFullYear();
        monthPickerVisible = false;
    }

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear--;
        } else {
            displayMonth--;
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear++;
        } else {
            displayMonth++;
        }
    }

    onVisibleChanged: {
        if (visible)
            resetToToday();
        else
            monthPickerVisible = false;
    }

    ColumnLayout {
        id: calendarContent
        anchors.fill: parent
        spacing: 12

        // ==================== HEADER ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Config.radius
                color: Qt.alpha(Config.surface1Color, 0.38)
                border.width: 1
                border.color: Qt.alpha(Config.accentColor, 0.20)

                Text {
                    anchors.centerIn: parent
                    text: "󰃭"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeLarge
                    color: Config.accentColor
                }
            }

            Text {
                text: "Calendar"
                font.family: Config.font
                font.bold: true
                font.pixelSize: Config.fontSizeLarge
                color: Config.textColor
                Layout.fillWidth: true
            }

            // Today badge
            Rectangle {
                Layout.preferredHeight: 26
                Layout.preferredWidth: 76
                radius: Config.radius
                color: todayHover.hovered ? Qt.alpha(Config.surface2Color, 0.58) : Qt.alpha(Config.surface1Color, 0.42)
                border.width: 1
                border.color: todayHover.hovered ? Qt.alpha(Config.accentColor, 0.26) : Qt.alpha(Config.textColor, 0.10)

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                RowLayout {
                    id: todayBadgeContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰃶"
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        color: Config.accentColor
                    }

                    Text {
                        text: root.today.toLocaleDateString(root.englishLocale, "MMM dd")
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: true
                        color: Config.textColor
                    }
                }

                HoverHandler {
                    id: todayHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.resetToToday()
                }
            }
        }

        // ==================== SEPARATOR ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Config.textColor, 0.14)
        }

        // ==================== MONTH NAVIGATION ====================
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: height / 2
                color: prevHover.hovered ? Qt.alpha(Config.surface1Color, 0.42) : "transparent"
                border.width: prevHover.hovered ? 1 : 0
                border.color: Qt.alpha(Config.textColor, 0.10)

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                }

                HoverHandler {
                    id: prevHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (root.monthPickerVisible)
                            root.displayYear--;
                        else
                            root.previousMonth();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: monthLabel.implicitHeight

                Text {
                    id: monthLabel
                    anchors.centerIn: parent
                    text: root.monthPickerVisible ? root.displayYear.toString() : root.monthNames[root.displayMonth] + " - " + root.displayYear
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    font.bold: true
                    color: monthHover.hovered || root.monthPickerVisible ? Config.accentColor : Config.textColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                HoverHandler {
                    id: monthHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.monthPickerVisible = !root.monthPickerVisible
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: height / 2
                color: nextHover.hovered ? Qt.alpha(Config.surface1Color, 0.42) : "transparent"
                border.width: nextHover.hovered ? 1 : 0
                border.color: Qt.alpha(Config.textColor, 0.10)

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeNormal
                    color: Config.subtextColor
                }

                HoverHandler {
                    id: nextHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (root.monthPickerVisible)
                            root.displayYear++;
                        else
                            root.nextMonth();
                    }
                }
            }
        }

        // ==================== CALENDAR BODY ====================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 218
            Layout.minimumHeight: 218
            Layout.maximumHeight: 218

            // ==================== MONTH PICKER ====================
            GridLayout {
                anchors.fill: parent
                visible: root.monthPickerVisible
                columns: 3
                rowSpacing: 8
                columnSpacing: 6

                Repeater {
                    model: 12

                    delegate: Rectangle {
                        id: monthItem

                        required property int index
                        readonly property bool selected: index === root.displayMonth

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Config.radius
                        color: selected ? Qt.alpha(Config.accentColor, 0.82) : (monthItemHover.hovered ? Qt.alpha(Config.surface1Color, 0.42) : "transparent")
                        border.width: selected || monthItemHover.hovered ? 1 : 0
                        border.color: selected ? Qt.alpha(Config.textReverseColor, 0.22) : Qt.alpha(Config.textColor, 0.10)

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.monthNames[monthItem.index].slice(0, 3)
                            font.family: Config.font
                            font.pixelSize: Config.fontSizeSmall
                            font.bold: monthItem.selected
                            color: monthItem.selected ? Config.textReverseColor : Config.textColor
                        }

                        HoverHandler {
                            id: monthItemHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                root.displayMonth = monthItem.index;
                                root.monthPickerVisible = false;
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                visible: !root.monthPickerVisible
                spacing: 12

                // ==================== DAY OF WEEK HEADER ====================
                DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: grid.locale

                    delegate: Text {
                        required property var model

                        horizontalAlignment: Text.AlignHCenter
                        text: model.shortName
                        font.family: Config.font
                        font.pixelSize: Config.fontSizeSmall
                        font.bold: true
                        color: (model.day === 0 || model.day === 6) ? Config.subtextColor : Config.textColor
                    }
                }

                // ==================== MONTH GRID ====================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MonthGrid {
                        id: grid

                        month: root.displayMonth
                        year: root.displayYear
                        anchors.fill: parent
                        spacing: 2
                        locale: root.englishLocale

                        delegate: Item {
                            id: dayCell

                            required property var model

                            readonly property bool isToday: model.today
                            readonly property bool isCurrentMonth: model.month === grid.month
                            readonly property bool isWeekend: {
                                const dow = model.date.getUTCDay();
                                return dow === 0 || dow === 6;
                            }

                            implicitWidth: implicitHeight
                            implicitHeight: dayText.implicitHeight + 8

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height)
                                height: width
                                radius: width / 2
                                color: dayCell.isToday ? Qt.alpha(Config.accentColor, 0.86) : "transparent"
                                border.width: dayCell.isToday ? 1 : 0
                                border.color: Qt.alpha(Config.textReverseColor, 0.22)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration
                                    }
                                }
                            }

                            Text {
                                id: dayText
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: dayCell.model.day
                                font.family: Config.font
                                font.pixelSize: Config.fontSizeSmall
                                font.bold: dayCell.isToday
                                color: {
                                    if (dayCell.isToday)
                                        return Config.textReverseColor;
                                    if (dayCell.isWeekend)
                                        return Config.subtextColor;
                                    return Config.textColor;
                                }
                                opacity: dayCell.isCurrentMonth ? 1.0 : 0.3
                            }
                        }
                    }

                    WheelHandler {
                        onWheel: event => {
                            if (event.angleDelta.y > 0)
                                root.previousMonth();
                            else if (event.angleDelta.y < 0)
                                root.nextMonth();
                        }
                    }
                }
            }
        }
    }
}
