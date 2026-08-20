import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    topLeftRadius: 8
    topRightRadius: 8
    bottomLeftRadius: 8
    bottomRightRadius: 28

    color: Theme.color.backgroundLight

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
            text: "󰕾"
            color: Theme.color.text
            font.bold: true
            font.pixelSize: Theme.font.sizeXXL
        }

        CustomSlider {
            Layout.preferredWidth: 160
            from: 0
            to: 1
            value: Api.player.volume
            onMoved: Api.player.setVolume(value)
        }

        Item { Layout.fillWidth: true }

        Text {
            Layout.maximumWidth: 460
            text: Api.player.lastError
            color: Theme.color.error
            font.pixelSize: Theme.font.sizeS
            elide: Text.ElideRight
        }
    }
}
