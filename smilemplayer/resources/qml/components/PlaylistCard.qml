import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    radius: 8
    color: Theme.color.backgroundLight

    function getSortIndex(key) {
        var mapping = ["title", "artist", "filename", "mtime", "duration"]
        var idx = mapping.indexOf(key)
        return idx >= 0 ? idx : 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "Tracks"
                // text: Api.library.playlistNames.length > 0
                //       ? Api.library.playlistNames[Api.library.currentPlaylist]
                //       : "Playlist"

                color: Theme.color.text
                font.pixelSize: Theme.font.sizeM
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                text: Api.player.playing ? "Playing" : "Stopped"
                color: Api.player.playing
                       ? Theme.color.accent
                       : Theme.color.textSecondary

                font.pixelSize: Theme.font.sizeS
                font.bold: true
            }

            BasicButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                label: ""
                fontSize: Theme.font.sizeL
                padding: 8
                backgroundColor: Theme.color.backgroundLight
                onClicked: Api.player.toggleSortDirection()
            }

            CustomButton {
                id: sortButton
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40
                label: sortMenu.model[sortMenu.currentIndex]
                fontSize: Theme.font.sizeS
                fontBold: true
                padding: 8
                backgroundColor: Theme.color.backgroundLighter
                onClicked: sortMenu.openForItem(sortButton)
            }

            SelectionMenu {
                id: sortMenu
                parent: Overlay.overlay
                width: 190
                title: "Sort by"
                model: ["Title", "Artist", "Filename", "MTime", "Duration"]
                currentIndex: 0

                onSelected: function(index) {
                    Api.player.sortCurrentPlaylist(
                        ["title", "artist", "filename", "mtime", "duration"][index]
                    )
                }
            }
        }

        ListView {
            id: tracksView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: Api.player.playlistModelObject

            delegate: Rectangle {
                required property string path
                required property string title
                required property string artist
                required property string album
                required property int durationMs
                required property string artUrl
                required property int trackIndex

                width: tracksView.width
                height: 64
                radius: 14
                color: trackIndex === Api.player.currentIndex
                       ? Theme.color.backgroundLighter
                       : trackMouse.containsMouse
                         ? Qt.lighter(
                               Theme.color.backgroundLighter,
                               1.08
                           )
                         : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 14
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Theme.color.backgroundDarker
                            clip: true

                            Image {
                                id: artwork
                                anchors.fill: parent
                                source: artUrl
                                sourceSize.width: 160
                                sourceSize.height: 160
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.color.textSecondary
                                font.pixelSize: Theme.font.sizeXXL
                                visible: artwork.status !== Image.Ready
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: title
                            color: Theme.color.text
                            // color: trackIndex === Api.player.currentIndex
                            //        ? Theme.color.text
                            //        : Theme.color.textSecondary

                            font.pixelSize: Theme.font.sizeM
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: artist !== "" ? artist : album
                            color: Theme.color.textSecondary
                            font.pixelSize: Theme.font.sizeS
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: Api.formatTime(durationMs)
                        color: Theme.color.textSecondary
                        font.pixelSize: Theme.font.sizeS
                    }
                }

                MouseArea {
                    id: trackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onDoubleClicked: Api.player.playIndex(trackIndex, true)
                    onClicked: Api.player.playIndex(trackIndex, false)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: tracksView.count === 0
                text: Api.library.playlistNames.length === 0
                      ? "Add a music folder"
                      : "No playable audio files found"

                color: Theme.color.textSecondary
                font.pixelSize: Theme.font.sizeM
            }
        }
    }

    Connections {
        target: Api.player
        function onSortKeyChanged() {
            sortMenu.currentIndex = getSortIndex(Api.player.sortKey)
        }
    }

    Component.onCompleted: {
        sortMenu.currentIndex = getSortIndex(Api.player.sortKey)
    }
}
