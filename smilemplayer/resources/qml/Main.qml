import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "components"
import "."

ApplicationWindow {
    id: root

    FontLoader {
        source: "fonts/JetBrainsMonoNerdFont-Regular.ttf"
    }

    width: 1220
    height: 760
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "SmileMPlayer"
    color: Theme.color.background

    property string focusedDescription: {
        var item = activeFocusItem
        if (!item) return ""
        if (item.objectName) return item.objectName
        return item.toString().split('(')[0]
    }

    Component.onCompleted: {
        Api.player = player
        Api.library = library
        playlist.tracksViewAlias.forceActiveFocus()
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

        PlaylistSidebar {
            objectName: "Sidebar"
            SplitView.preferredWidth: 280
            SplitView.minimumWidth: 140
            SplitView.maximumWidth: 600
            SplitView.fillHeight: true
        }

        SplitView {
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            orientation: Qt.Vertical
            handle: Item { implicitHeight: 20 }

            NowPlayingCard {
                id: nowPlaying
                SplitView.preferredHeight: 256
                SplitView.minimumHeight: 256
                SplitView.maximumHeight: 400
                SplitView.fillWidth: true
            }

            PlaylistCard {
                id: playlist
                objectName: "Playlist"
                SplitView.fillWidth: true
                SplitView.fillHeight: true
            }

            StatusBarCard {
                SplitView.preferredHeight: 60
                SplitView.minimumHeight: 60
                SplitView.maximumHeight: 80
                SplitView.fillWidth: true
                focusedItemText: root.focusedDescription
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
