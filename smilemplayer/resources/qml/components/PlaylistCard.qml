pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property int minColumnWidth: 270
    readonly property alias tracksViewAlias: tracksView

    radius: 8
    color: Theme.color.backgroundLight

    function getSortIndex(key) {
        var mapping = ["title", "artist", "filename", "mtime", "duration"]
        var idx = mapping.indexOf(key)
        return idx >= 0 ? idx : 0
    }

    MouseArea {
        anchors.fill: parent
        onClicked: tracksView.forceActiveFocus()
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

        GridView {
            id: tracksView
            objectName: "Playlist Grid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            activeFocusOnTab: true
            focus: true

            readonly property int columns: Math.max(1, Math.floor(width / root.minColumnWidth))

            cellWidth: width / columns
            cellHeight: 72

            model: Api.player.playlistModelObject

            property int selectedIndex: -1

            // Scrollbar
            ScrollBar.vertical: ScrollBar {
                id: vScroll
                policy: ScrollBar.AsNeeded
                visible: true
                interactive: true
                opacity: hovered ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                background: Rectangle {
                    implicitWidth: 14
                    color: "transparent"
                }

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: Theme.color.textSecondary
                    opacity: 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Keyboard navigation
            Keys.onPressed: (event) => {
                if (tracksView.count === 0) return

                const current = tracksView.selectedIndex
                let next = current

                switch (event.key) {
                    case Qt.Key_Down:
                        next = current + tracksView.columns
                        break
                    case Qt.Key_Up:
                        next = current - tracksView.columns
                        break
                    case Qt.Key_Right:
                        if (tracksView.columns > 1)
                            next = current + 1
                        else
                            return
                        break
                    case Qt.Key_Left:
                        if (tracksView.columns > 1)
                            next = current - 1
                        else
                            return
                        break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        if (current >= 0 && current < tracksView.count) {
                            Api.player.playIndex(current, true)
                            event.accepted = true
                        }
                        return
                    default:
                        return
                }

                if (next < 0) next = 0
                if (next >= tracksView.count) next = tracksView.count - 1

                if (next !== current) {
                    tracksView.selectedIndex = next
                    tracksView.positionViewAtIndex(next, GridView.Contain)
                    event.accepted = true
                }
            }

            function setSelectedIndexByTrack(index) {
                tracksView.selectedIndex = index
                tracksView.forceActiveFocus()
                tracksView.positionViewAtIndex(index, GridView.Contain)
            }

            delegate: Rectangle {
                required property string path
                required property string title
                required property string artist
                required property string album
                required property int durationMs
                required property string artUrl
                required property int trackIndex

                width: tracksView.cellWidth - 8
                height: tracksView.cellHeight - 8
                radius: 14

                readonly property bool isPlaying: trackIndex === Api.player.currentIndex
                readonly property bool isSelected: trackIndex === tracksView.selectedIndex

                color: isPlaying
                       ? Theme.color.backgroundLighter
                       : isSelected
                         ? Qt.lighter(Theme.color.backgroundLighter, 1.15)
                         : trackMouse.containsMouse
                           ? Qt.lighter(Theme.color.backgroundLighter, 1.08)
                           : "transparent"

                border.width: isSelected ? 2 : 0
                border.color: isSelected ? Theme.color.border : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    // Cover art
                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Theme.color.backgroundDarker
                            clip: true

                            Image {
                                id: artwork
                                anchors.fill: parent
                                source: artUrl
                                sourceSize.width: 120
                                sourceSize.height: 120
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                color: Theme.color.textSecondary
                                font.pixelSize: Theme.font.sizeL
                                visible: artwork.status !== Image.Ready
                            }
                        }
                    }

                    // Title and artist
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: title
                            color: Theme.color.text
                            font.pixelSize: Theme.font.sizeMS
                            font.bold: true
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

                    // Duration
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

                    onClicked: {
                        tracksView.setSelectedIndexByTrack(trackIndex)
                        Api.player.playIndex(trackIndex, false)
                    }
                    onDoubleClicked: Api.player.playIndex(trackIndex, true)
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
            sortMenu.currentIndex = root.getSortIndex(Api.player.sortKey)
        }
    }

    Component.onCompleted: {
        sortMenu.currentIndex = getSortIndex(Api.player.sortKey)
        if (tracksView.count > 0) {
            tracksView.selectedIndex = 0
            tracksView.positionViewAtIndex(0, GridView.Contain)
        }
    }
}
