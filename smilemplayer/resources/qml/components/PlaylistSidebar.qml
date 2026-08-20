import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    topLeftRadius: 28
    topRightRadius: 8
    bottomLeftRadius: 28
    bottomRightRadius: 8

    color: Theme.color.backgroundLight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CustomButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: ""
                fontSize: Theme.font.sizeXL / 1.05
                padding: 12
                onClicked: folderDialog.open()
            }

            CustomButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: ""
                fontSize: Theme.font.sizeXXL
                padding: 12
                canClick: Api.library.playlistNames.length > 0
                onClicked: Api.library.rescanCurrent()
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Playlists"
            color: Theme.color.textSecondary
            font.pixelSize: Theme.font.sizeL
            font.bold: true
            topPadding: 6
        }

        ListView {
            id: playlistView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: Api.library.playlistNames

            delegate: Rectangle {
                required property int index
                required property string modelData

                width: playlistView.width
                height: 48
                radius: 14

                color: {
                    if (index === Api.library.currentPlaylist)
                        return Theme.color.backgroundLighter

                    return playlistMouse.containsMouse
                        ? Qt.lighter(Theme.color.backgroundLighter, 1.08)
                        : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10

                    spacing: 10

                    Text {
                        text: ""
                        color: index === Api.library.currentPlaylist
                               ? Theme.color.accent
                               : Theme.color.textSecondary

                        font.pixelSize: Theme.font.sizeM
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: modelData
                        elide: Text.ElideMiddle
                        color: index === Api.library.currentPlaylist
                               ? Theme.color.text
                               : Theme.color.textSecondary

                        font.pixelSize: Theme.font.sizeM
                    }

                    BasicButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        label: ""
                        fontSize: Theme.font.sizeXL
                        padding: 8
                        opacity: hovered ? 1 : 0
                        onClicked: Api.library.removePlaylist(index)
                    }
                }

                MouseArea {
                    id: playlistMouse
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    onClicked: Api.library.setCurrentPlaylist(index)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: Api.library.playlistNames.length === 0
                  ? "Add a folder as a playlist. Subfolders are scanned automatically."
                  : "Folders are stored in ~/.config/SmileMPlayer/config.json"

            color: Theme.color.textSecondary
            font.pixelSize: Theme.font.sizeS
            wrapMode: Text.Wrap
        }
    }
}
