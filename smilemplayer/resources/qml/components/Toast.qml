import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    readonly property bool active: text.length > 0

    height: active ? 44 : 0
    opacity: active ? 1 : 0
    radius: 32
    border.color: Theme.color.border
    border.width: 2
    color: Theme.color.backgroundLight

    Behavior on height {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: timer
        interval: 2600
        onTriggered: root.text = ""
    }

    function show(message) {
        root.text = message
        timer.restart()
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 26
        text: root.text
        color: Theme.color.text
        font.pixelSize: Theme.font.sizeS
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
