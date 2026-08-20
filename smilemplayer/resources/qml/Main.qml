import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "components"
import "."

ApplicationWindow {
    id: root

    width: 1220
    height: 760
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "SmileMPlayer"
    color: Theme.color.background

    Component.onCompleted: {
        Api.player = player
        Api.library = library
    }

    FolderDialog {
        id: folderDialog
        title: "Add music folder"
        onAccepted: Api.library.addFolder(selectedFolder.toString())
    }

    SplitView {
        anchors.fill: parent
        anchors.margins: 20
        orientation: Qt.Horizontal
        handle: Item { implicitWidth: 20 }

        // handle: Rectangle {
        //     implicitWidth: 20
        //     color: "transparent"

        //     Rectangle {
        //         anchors.centerIn: parent
        //         width: SplitHandle.hovered || SplitHandle.pressed ? 4 : 2
        //         height: parent.height
        //         radius: 2

        //         color: SplitHandle.pressed
        //                ? Theme.color.accent
        //                : SplitHandle.hovered
        //                  ? Theme.color.backgroundLighter
        //                  : Theme.color.border
        //     }
        // }

        PlaylistSidebar {
            SplitView.preferredWidth: 280
            SplitView.minimumWidth: 140
            SplitView.maximumWidth: 600
            SplitView.fillHeight: true
        }

        ColumnLayout {
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            spacing: 20

            NowPlayingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
            }

            PlaylistCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            StatusBarCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
            }
        }
    }

    Connections {
        target: Api.player

        function onStatusMessage(message) {
            toast.show(message)
        }
    }

    Toast {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: Math.min(parent.width - 40, 250)
    }
}
