import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    color: Theme.color.backgroundLight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Lyrics"
                color: Theme.color.textSecondary
                font.pixelSize: Theme.font.sizeL
                font.bold: true
            }

            BasicButton {
                id: modeButton
                Layout.preferredWidth: 78
                Layout.preferredHeight: 34
                label: Api.player && Api.player.lyricsSyncMode === "word" ? "Word" : "Line"
                fontSize: Theme.font.sizeS
                padding: 8
                canClick: Api.player !== null
                onClicked: syncModeMenu.openForItem(modeButton)
            }

            SelectionMenu {
                id: syncModeMenu
                width: 130
                model: ["Line", "Word"]
                currentIndex: Api.player && Api.player.lyricsSyncMode === "word" ? 1 : 0
                title: "Sync mode"

                onSelected: function(index, value) {
                    Api.player.lyricsSyncMode = index === 1 ? "word" : "line"
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: lyricsView
                anchors.fill: parent
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: Api.player ? Api.player.lyrics : []
                visible: Api.player !== null && Api.player.lyricsAvailable

                delegate: Item {
                    id: lyricDelegate

                    required property int index
                    required property var modelData

                    width: lyricsView.width
                    implicitHeight: lineContent.implicitHeight + 10

                    readonly property bool current:
                        Api.player !== null && index === Api.player.currentLyricIndex

                    ColumnLayout {
                        id: lineContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            visible:
                                Api.player === null ||
                                Api.player.lyricsSyncMode === "line" ||
                                !lyricDelegate.modelData.enhanced

                            text: lyricDelegate.modelData.text
                            color: lyricDelegate.current
                                ? Theme.color.text
                                : Theme.color.textSecondary
                            font.pixelSize: lyricDelegate.current
                                ? Theme.font.sizeM
                                : Theme.font.sizeMS
                            font.bold: lyricDelegate.current
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }

                        Flow {
                            id: wordFlow
                            Layout.fillWidth: true
                            visible:
                                Api.player !== null &&
                                Api.player.lyricsSyncMode === "word" &&
                                lyricDelegate.modelData.enhanced

                            spacing: 0

                            Repeater {
                                model: lyricDelegate.modelData.words

                                delegate: Item {
                                    required property int index
                                    required property var modelData

                                    implicitWidth: wordText.implicitWidth
                                    implicitHeight: wordText.implicitHeight
                                    width: implicitWidth
                                    height: implicitHeight

                                    Text {
                                        id: wordText
                                        anchors.fill: parent
                                        text: modelData.text
                                        color:
                                            lyricDelegate.current &&
                                            index === Api.player.currentLyricWordIndex
                                                ? Theme.color.accent
                                                : lyricDelegate.current
                                                    ? Theme.color.text
                                                    : Theme.color.textSecondary
                                        font.pixelSize: lyricDelegate.current
                                            ? Theme.font.sizeM
                                            : Theme.font.sizeMS
                                        font.bold:
                                            lyricDelegate.current &&
                                            index === Api.player.currentLyricWordIndex
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: lyricDelegate.current
                                        acceptedButtons: Qt.LeftButton
                                        onClicked:
                                            Api.player.seekToLyricWord(
                                                lyricDelegate.index,
                                                index
                                            )
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        enabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: Api.player.seekToLyric(lyricDelegate.index)
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    opacity: lyricDelegate.current ? 1.0 : 0.72
                }

                Connections {
                    target: Api.player

                    function onCurrentLyricChanged() {
                        if (Api.player && Api.player.currentLyricIndex >= 0) {
                            lyricsView.positionViewAtIndex(
                                Api.player.currentLyricIndex,
                                ListView.Center
                            )
                        }
                    }

                    function onLyricsChanged() {
                        if (Api.player && Api.player.lyricsAvailable) {
                            lyricsView.positionViewAtIndex(
                                Math.max(0, Api.player.currentLyricIndex),
                                ListView.Center
                            )
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 6
                visible: !Api.player || !Api.player.lyricsAvailable

                Text {
                    width: parent.width
                    text: Api.player && Api.player.title !== "Nothing playing"
                        ? "No lyrics found"
                        : "Nothing playing"
                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeM
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: Api.player && Api.player.title !== "Nothing playing"
                        ? "Add a matching .lrc file next to the audio track."
                        : "Lyrics will appear here when a track is playing."
                    color: Theme.color.textSecondary
                    font.pixelSize: Theme.font.sizeS
                    opacity: 0.8
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
