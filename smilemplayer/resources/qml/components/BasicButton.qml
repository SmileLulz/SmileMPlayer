import QtQuick
import ".."

Item {
    id: root

    property bool canClick: true
    property string label: "Label"

    property real fontSize: 16
    property real padding: 16
    property real minimumWidth: 178

    property real radiusTopLeft: 14
    property real radiusTopRight: 14
    property real radiusBottomRight: 14
    property real radiusBottomLeft: 14

    property color textColor: Theme.color.text
    property color textColorSecondary: Theme.color.textSecondary

    property color backgroundColor: Theme.color.backgroundLighter
    property color backgroundColorHover: Qt.lighter(backgroundColor, 1.25)
    property color backgroundColorPressed: Qt.darker(backgroundColor, 1.25)
    property color backgroundColorDisabled: Theme.color.backgroundLight

    signal clicked(var mouse)

    readonly property bool hovered: canClick && mouseArea.containsMouse
    readonly property bool pressed: canClick && mouseArea.pressed

    readonly property color currentTextColor:
        !canClick
            ? textColorSecondary
            : pressed
                ? textColorSecondary
                : textColor

    readonly property color currentBackgroundColor:
        !canClick
            ? backgroundColorDisabled
            : pressed
                ? backgroundColorPressed
                : hovered
                    ? backgroundColorHover
                    : backgroundColor

    implicitWidth: Math.max(minimumWidth, textBox.implicitWidth + padding * 2)
    implicitHeight: textBox.implicitHeight + padding * 2

    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: root.radiusTopLeft
        topRightRadius: root.radiusTopRight
        bottomRightRadius: root.radiusBottomRight
        bottomLeftRadius: root.radiusBottomLeft
        color: root.currentBackgroundColor

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Text {
        id: textBox
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: root.label
        color: root.currentTextColor
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.canClick
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onClicked: function(mouse) {
            root.clicked(mouse)
        }
    }
}
